###############################################################################
## $Id$
##
## Nasal for dual control of a ky196 Comm radio over the multiplayer network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Note:
#  The ky196 pick animations require that the master or slave object is
#  available as aircraft_dual_control.ky196.
#

# Slave button presses.
var swap_btn    = "swap-clicked";
var freq_decS   = "freq-decS-clicked";
var freq_incS   = "freq-incS-clicked";
var freq_decL   = "freq-decL-clicked";
var freq_incL   = "freq-incL-clicked";

# Settings
var freq_selected = "frequencies/selected-mhz";
var freq_standby  = "frequencies/standby-mhz";

###########################################################################
var master_ky196 = {
  swap : func(n) {
    var b = props.globals.getNode("instrumentation/comm[" ~ n ~
                                  "]/frequencies");
    var tmp = b.getChild("selected-mhz").getValue();
    b.getChild("selected-mhz").setValue(b.getChild("standby-mhz").getValue());
    b.getChild("standby-mhz").setValue(tmp);
  },
  set_volume : func(n, d) {
    var v = getprop("instrumentation/ky-196/volume-adjust");
    setprop("instrumentation/ky-196/volume-adjust", v + d);
    setprop("instrumentation/ky-196/comm-num", n);
  },
  adjust_frequency : func(n, d) {
    var f  = props.globals.getNode("instrumentation/comm[" ~ n ~ "]/" ~
                                   freq_standby);
    var i  = int(f.getValue());
    var fr = f.getValue() - i;
    if (math.abs(d) < 0.99) {
      # Adjust only fractional part.
      fr += d;
      if (fr < 0)  { fr += 1; }
      if (fr >= 1) { fr -= 1; }
    } else {
      # Adjust only integer part.
      i += d;
      if (i < 118) { i = 136; }
      if (i > 136) { i = 118; }
    }
    f.setValue(i + fr);
  }
};

###########################################################################
var slave_ky196 = {
  new : func(root) {
    obj = {};
    obj.parents = [slave_ky196];
    obj.root = root;
    return obj;
  },
  swap : func(n) {
    var b = "instrumentation/comm[" ~ n ~ "]/"; 
    var p = props.globals.getNode(b ~ swap_btn);
    print("KY196[" ~ n ~ "].SWAP");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
      # Swap locally to improve user experience.
      master_ky196.swap(n);
      me.root.getNode(b ~ freq_selected).
        setValue(props.globals.getNode(b ~ freq_selected).getValue());
      me.root.getNode(b ~ freq_standby).
        setValue(props.globals.getNode(b ~ freq_standby).getValue());
    }
  },
  set_volume : func(n, d) {
  },
  adjust_frequency : func(n, d) {
    var b = "instrumentation/comm[" ~ n ~ "]/"; 
    var p = 0;
    if (abs(d) < 0.99) {
      p = (d < 0) ? props.globals.getNode(b ~ freq_decS)
                  : props.globals.getNode(b ~ freq_incS);
    } else {
      p = (d < 0) ? props.globals.getNode(b ~ freq_decL)
                  : props.globals.getNode(b ~ freq_incL);
    }
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
      # Update locally to improve user experience. Not that bright, yet :)
      #master_ky196.adjust_frequency(n, d);
      #me.root.getNode(b ~ freq_standby).
      #  setValue(props.globals.getNode(b ~ freq_standby).getValue());
    }
  }
};
