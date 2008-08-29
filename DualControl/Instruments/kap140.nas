###############################################################################
## $Id$
##
## Nasal for dual control of a KAP 140 autopilot over the multiplayer
## network.
##
##  Copyright (C) 2008  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Note:
#  This module MUST be loaded as kap140 and the real kap140.nas
#  MUST be loaded as kap140_implementation.
#

# Slave button presses.
var ap_btn    = "ap-btn";
var hdg_btn   = "hdg-btn";
var nav_btn   = "nav-btn";
var apr_btn   = "apr-btn";
var alt_btn   = "alt-btn";
var rev_btn   = "rev-btn";
var down_btn  = "down-btn";
var up_btn    = "up-btn";
var arm_btn   = "arm-btn";
var baro_press_btn    = "baro-press-btn";
var baro_release_btn  = "baro-release-btn";

###############################################################################
# API function wrappers.

var apButton = func {
    kap140.apButton();
}

var hdgButton = func {
    kap140.hdgButton();
}

var navButton = func {
    kap140.navButton();
}

var aprButton = func {
    kap140.aprButton();
}

var altButton = func {
    kap140.altButton();
}

var revButton = func {
    kap140.revButton();
}

var downButton = func {
    kap140.downButton();
}

var upButton = func {
    kap140.upButton();
}

var armButton = func {
    kap140.armButton();
}

var baroButtonPress = func {
    kap140.baroButtonPress();
}

var baroButtonRelease = func {
    kap140.baroButtonRelease();
}

var knobSmallDown = func {
    kap140.knobSmallDown();
}

var knobSmallUp = func {
    kap140.knobSmallUp();
}

var knobLargeDown = func {
    kap140.knobLargeDown();
}

var knobLargeUp = func {
    kap140.knobLargeUp();
}

###############################################################################

###########################################################################
# The master is just the standard implementation. 
var master_kap140 =
    contains(globals, "kap140_implementation") ? kap140_implementation : nil;

var make_slave_to = func(airoot) {
  kap140 = slave_kap140.new(airoot);
}


###########################################################################
var slave_kap140 = {
  new : func(airoot) {
    obj = {};
    obj.parents = [slave_kap140];
    obj.root = airoot;
    obj.base = props.globals.getNode("/autopilot/kap140/buttons", 1);
    return obj;
  },
  apButton : func {
    var p = me.base.getNode(ap_btn);
    print("KAP140.AP");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  hdgButton : func {
    var p = me.base.getNode(hdg_btn);
    print("KAP140.HDG");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  navButton : func {
    var p = me.base.getNode(nav_btn);
    print("KAP140.NAV");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  aprButton : func {
    var p = me.base.getNode(apr_btn);
    print("KAP140.APR");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  altButton : func {
    var p = me.base.getNode(alt_btn);
    print("KAP140.ALT");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  revButton : func {
    var p = me.base.getNode(rev_btn);
    print("KAP140.REV");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  downButton : func {
    var p = me.base.getNode(down_btn);
    print("KAP140.DN");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  upButton : func {
    var p = me.base.getNode(up_btn);
    print("KAP140.UP");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  armButton : func {
    var p = me.base.getNode(arm_btn);
    print("KAP140.ARM");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  baroButtonPress : func {
    var p = me.base.getNode(baro_press_btn);
    print("KAP140.BARO_PRESS");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  baroButtonRelease : func {
    var p = me.base.getNode(baro_release_btn);
    print("KAP140.BARO_RELEASE");
    if (!p.getValue()) {
      p.setValue(1);
      settimer(func { p.setValue(0); },
               1.0);
    }
  },
  knobSmallDown : func {
  },
  knobSmallUp : func {
  },
  knobLargeDown : func {
  },
  knobLargeUp : func {
  },
};

###########################################################################
#  The KAP140 pick animations default to master.
var kap140 = master_kap140;
