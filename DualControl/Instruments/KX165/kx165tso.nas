###############################################################################
## $Id$
##
## Nasal for dual control of a KX165 NavComm radio over the multiplayer
## network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Note:
#  This module MUST be loaded as KX165.
#

# Slave button presses.
var swap_btn    = "frq-swap-btn";
var freq_decS   = "freq-decS-clicked";
var freq_incS   = "freq-incS-clicked";
var freq_decL   = "freq-decL-clicked";
var freq_incL   = "freq-incL-clicked";

# Settings
var freq_selected = "frequencies/selected-mhz";
var freq_standby  = "frequencies/standby-mhz";

###########################################################################
var master_kx165tso = {
  new : func(n) {
    obj = {};
    obj.parents = [master_kx165tso];
    obj.nav_base  = props.globals.getNode("instrumentation/nav[" ~ n ~ "]");
    obj.comm_base = props.globals.getNode("instrumentation/comm[" ~ n ~ "]");
    return obj;
  },
  swap_nav : func() {
    var tmp = me.nav_base.getNode(freq_selected).getValue();
    me.nav_base.getNode(freq_selected).setValue
      (me.nav_base.getNode(freq_standby).getValue());
    me.nav_base.getNode(freq_standby).setValue(tmp);
  },
  swap_comm : func() {
    var tmp = me.comm_base.getNode(freq_selected).getValue();
    me.comm_base.getNode(freq_selected).setValue
      (me.comm_base.getNode(freq_standby).getValue());
    me.comm_base.getNode(freq_standby).setValue(tmp);
  },
  adjust_nav_frequency : func(d) {
    adjust_radio_frequency(
      me.nav_base.getNode(freq_standby),
      d,
      108,
      117.95);
  },
  adjust_comm_frequency : func(d) {
    adjust_radio_frequency(
      me.comm_base.getNode(freq_standby),
      d,
      118,
      135.975);
  }
};

###########################################################################
var slave_kx165tso = {
  new : func(n, airoot) {
    obj = {};
    obj.parents = [slave_kx165tso];
    obj.root = airoot;
    obj.nav_base  = props.globals.getNode("instrumentation/nav[" ~ n ~ "]/");
    obj.comm_base = props.globals.getNode("instrumentation/comm[" ~ n ~ "]/");
    return obj;
  },
  swap_nav : func() {
    var p = me.nav_base.getNode(swap_btn);
    print("KX165tso[?].NAVSWAP");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
      # Swap locally to improve user experience.
#      master_kx165tso.swap_nav(n);
      # Swap below the pilot node in case the animations look there.
#      me.root.getNode(b ~ freq_selected, 1).
#        setValue(props.globals.getNode(b ~ freq_selected).getValue());
#      me.root.getNode(b ~ freq_standby, 1).
#        setValue(props.globals.getNode(b ~ freq_standby).getValue());
    }
  },
  swap_comm : func() {
    var p = me.comm_base.getNode(swap_btn);
    print("KX165tso[?].COMMSWAP");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
      # Swap locally to improve user experience.
#      master_kx165tso.swap_comm(n);
      # Swap below the pilot node in case the animations look there.
#      me.root.getNode(b ~ freq_selected, 1).
#        setValue(props.globals.getNode(b ~ freq_selected).getValue());
#      me.root.getNode(b ~ freq_standby, 1).
#        setValue(props.globals.getNode(b ~ freq_standby).getValue());
    }
  },
  adjust_nav_frequency : func(d) {
    var p = 0;
    if (abs(d) < 0.99) {
      p = (d < 0) ? me.nav_base.getNode(freq_decS)
                  : me.nav_base.getNode(freq_incS);
    } else {
      p = (d < 0) ? me.nav_base.getNode(freq_decL)
                  : me.nav_base.getNode(freq_incL);
    }
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  adjust_comm_frequency : func(d) {
    var p = 0;
    if (abs(d) < 0.99) {
      p = (d < 0) ? me.comm_base.getNode(freq_decS)
                  : me.comm_base.getNode(freq_incS);
    } else {
      p = (d < 0) ? me.comm_base.getNode(freq_decL)
                  : me.comm_base.getNode(freq_incL);
    }
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  }
};

###########################################################################
#  The KX-165 pick animations default to master.
#  NOTE: Use make_master() and make_slave_to().
#        Do NOT change kx165tso directly.
var kx165tso = [master_kx165tso.new(0), master_kx165tso.new(1)];


###########################################################################
# n - NavComm#
var make_master = func(n) {
  kx165tso[n] = master_kx165tso.new(n);
}

###########################################################################
# n - NavComm#
var make_slave_to = func(n, airoot) {
  kx165tso[n] = slave_kx165tso.new(n, airoot);
}

###########################################################################
# n - NavComm#
swap_nav = func(n) {
  kx165tso[n].swap_nav();
}

###########################################################################
# n - NavComm#
swap_comm = func(n, b) {
  kx165tso[n].comm_base.getNode(swap_btn).setValue(b);
  if (b) kx165tso[n].swap_comm();
}

###########################################################################
# n - NavComm#
# d - adjustment
adjust_nav_frequency = func(n, d) {
  kx165tso[n].adjust_nav_frequency(d);
}

###########################################################################
# n - NavComm#
# d - adjustment
adjust_comm_frequency = func(n, d) {
  kx165tso[n].adjust_comm_frequency(d);
}

###########################################################################
# Generic frequency stepper.
#  f   - frequency property
#  d   - change
#  min - min frequency
#  max - max frequency
var adjust_radio_frequency = func(f, d, min, max) {
  var old = f.getValue();
  var new = old + d;
  if (new < min - 0.005) { new = int(max) + (new - int(new)); }
  if (new > max + 0.005) {
      new = int(min) + (new - int(new));
      if (int(new + 0.005) > min) new -= 1;
  }
#  print("Old: " ~ old ~ "  Intermediate: " ~ (old + d) ~ "  New: " ~ new);
  f.setValue(new);
}
