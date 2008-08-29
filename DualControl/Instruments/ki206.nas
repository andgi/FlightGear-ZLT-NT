###############################################################################
## $Id$
##
## Nasal for dual control of a KI-206 VOR indicator over the multiplayer
## network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Note:
#   This module MUST be loaded as KI206.

# Slave button presses.
var radial_decS   = "radial-decS-clicked";
var radial_incS   = "radial-incS-clicked";
# Only one step size implemented.

###########################################################################
var master_ki206 = {
  new : func(n) {
    obj = {};
    obj.parents = [master_ki206];
    obj.base = props.globals.getNode("instrumentation/nav[" ~ n ~ "]/");
    return obj;
  },  
  adjust_radial : func(d) {
    p = me.base.getNode("radials/selected-deg");
    var v = p.getValue() + d;
    if (v < 0)   { v += 360; };
    if (v > 360) { v -= 360; };
    p.setValue(v);
  }
};

###########################################################################
var slave_ki206 = {
  new : func(n, airoot) {
    obj = {};
    obj.parents = [slave_ki206];
    obj.root = airoot;
    obj.base = props.globals.getNode("instrumentation/nav[" ~ n ~ "]/");
    return obj;
  },
  adjust_radial : func(d) {
    var p = 0;
    if (abs(d) < 0.99) {
      p = (d < 0) ? me.base.getNode(radial_decS)
                  : me.base.getNode(radial_incS);
    } else {
      p = (d < 0) ? me.base.getNode(radial_decS)
                  : me.base.getNode(radial_incS);
    }
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  }
};

###########################################################################
# The KI-206 pick animations default to master.
# NOTE: Use make_master() and make_slave_to(). Do NOT change ki206 directly. 
var ki206 = [master_ki206.new(0), master_ki206.new(1)];

###########################################################################
# n - Nav#
var make_master = func(n) {
  ki206[n] = master_ki206.new(n);
}

###########################################################################
# n - Nav#
var make_slave_to = func(n, airoot) {
  ki206[n] = KI206.slave_ki206.new(n, airoot);
}

###########################################################################
# n - Nav#
# d - adjustment delta
var adjust_radial = func(n, d) {
  ki206[n].adjust_radial(d);
}