###############################################################################
## $Id$
##
## Nasal for dual control of a KR-87 ADF radio over the multiplayer
## network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Note:
#  This module MUST be loaded as KR87.
#

# Slave button presses.
var swap_btn    = "frq-btn";
var freq_decS   = "freq-decS-clicked";
var freq_incS   = "freq-incS-clicked";
var freq_decL   = "freq-decL-clicked";
var freq_incL   = "freq-incL-clicked";

var bfo_btn     = "bfo-btn";

# Settings
var freq_selected = "frequencies/selected-khz";
var freq_standby  = "frequencies/standby-khz";

###########################################################################
var master_kr87 = {
  new : func(n) {
    obj = {};
    obj.parents = [master_kr87];
    obj.base    = props.globals.getNode("instrumentation/adf[" ~ n ~ "]");
#    obj.base.getNode("right-display", 1).
#      setValue(obj.base.getNode(freq_standby).getValue());
    return obj;
  },
  swap : func() {
    var tmp = me.base.getNode(freq_selected).getValue();
    me.base.getNode(freq_selected).setValue
      (me.base.getNode(freq_standby).getValue());
    me.base.getNode(freq_standby).setValue(tmp);
    me.base.getNode("right-display").setValue(tmp);
  },
  adjust_frequency : func(d) {
    adjust_radio_frequency(
      me.base.getNode(freq_standby),
      d,
      100,
      1300);
    me.base.getNode("right-display").
      setValue(me.base.getNode(freq_standby).getValue());
  },
  toggle_BFO : func {
    var p = me.base.getNode(bfo_btn).getValue() ? 0 : 1;
    me.base.getNode(bfo_btn).setValue(p);
    me.base.getNode("ident-audible").setValue(p);
  }
};

###########################################################################
var slave_kr87 = {
  new : func(n, airoot) {
    obj = {};
    obj.parents = [slave_kr87];
    obj.root    = airoot;
    obj.base    = props.globals.getNode("instrumentation/adf[" ~ n ~ "]/");
 #   obj.base.getNode("right-display", 1).
 #     setValue(obj.base.getNode(freq_standby).getValue());
    return obj;
  },
  swap : func() {
    var p = me.base.getNode(swap_btn);
    print("KR87[?].SWAP");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  adjust_frequency : func(d) {
    var p = 0;
    if (abs(d) < 50) {
      p = (d < 0) ? me.base.getNode(freq_decS)
                  : me.base.getNode(freq_incS);
    } else {
      p = (d < 0) ? me.base.getNode(freq_decL)
                  : me.base.getNode(freq_incL);
    }
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
};

###########################################################################
#  The KR-87 pick animations default to master.
#  NOTE: Use make_master() and make_slave_to().
#        Do NOT change kr87 directly.
var kr87 = [master_kr87.new(0), master_kr87.new(1)];


###########################################################################
# n - ADF#
var make_master = func(n) {
  kr87[n] = master_kr87.new(n);
}

###########################################################################
# n - ADF#
var make_slave_to = func(n, airoot) {
  kr87[n] = slave_kr87.new(n, airoot);
}

###########################################################################
# n - ADF#
swap = func(n) {
  kr87[n].swap();
}

###########################################################################
# n - ADF#
# d - adjustment
adjust_frequency = func(n, d) {
  kr87[n].adjust_frequency(d);
}

###########################################################################
# n - ADF#
# p - pressed
toggle_BFO = func(n) {
  kr87[n].toggle_BFO();
}

###########################################################################
# Generic frequency stepper.
#  f   - frequency property
#  d   - change
#  min - min frequency
#  max - max frequency
var adjust_radio_frequency = func(f, d, min, max) {
  var fr  = int(f.getValue());
  fr += d;
  if (fr < min) { fr = min; }
  if (fr > max) { fr = max; }
  f.setValue(fr);
}
