###############################################################################
## $Id$
##
## Zeppelin NT-07 airship
##
##  Copyright (C) 2008  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

###############################################################################
var auto_weighoff = func {
    print("auto_weighoff not implemented.");
}

###############################################################################
# Debug display - stand in instrumentation.
var debug_display_view_handler = {
    init : func {
        if (contains(me, "left")) return;

        me.left  = screen.display.new(20, 10);
        me.right = screen.display.new(-250, 20);
        # Static condition
        me.left.add
            ("/fdm/jsbsim/instrumentation/gas-pressure-psf");
        me.left.add
            ("/fdm/jsbsim/buoyant_forces/gas-cell/ballonet[0]/volume-ft3",
             "/fdm/jsbsim/buoyant_forces/gas-cell/ballonet[1]/volume-ft3");
        me.left.add("/fdm/jsbsim/static-condition/net-lift-lbs");
        # C.G.
        me.left.add("/fdm/jsbsim/inertia/cg-x-in");
#        me.left.add(static_trim_p);
#        me.left.add("/fdm/jsbsim/mooring/total-distance-ft");
        # Engines
        me.right.add("/fdm/jsbsim/fcs/etc/propeller-speed-cmd-rpm[0]",
                     "/engines/engine[0]/thruster/rpm",
                     "/fdm/jsbsim/propulsion/engine[0]/blade-angle");
        me.right.add("/fdm/jsbsim/fcs/etc/propeller-speed-cmd-rpm[1]",
                     "/engines/engine[1]/thruster/rpm",
                     "/fdm/jsbsim/propulsion/engine[1]/blade-angle");
        me.right.add("/fdm/jsbsim/fcs/etc/propeller-speed-cmd-rpm[2]",
                     "/engines/engine[2]/thruster/rpm",
                     "/fdm/jsbsim/propulsion/engine[2]/blade-angle");
        me.shown = 1;
        me.stop();
    },
    start  : func {
        if (!me.shown) {
            me.left.toggle();
            me.right.toggle();
        }
        me.shown = 1;
    },
    stop   : func {
        if (me.shown) {
            me.left.toggle();
            me.right.toggle();
        }
        me.shown = 0;
    }
};

# Install the debug display for some views.
setlistener("/sim/signals/fdm-initialized", func {
    view.manager.register("Pilot View", debug_display_view_handler);
    view.manager.register("Copilot View", debug_display_view_handler);
    print("Debug instrumentation ... check");
});

###############################################################################
# fake part of the electrical system.
var fake_electrical = func {
    setprop("systems/electrical/ac-volts", 15);

    setprop("/systems/electrical/outputs/comm[0]", 24.0);
    setprop("/systems/electrical/outputs/comm[1]", 24.0);
    setprop("/systems/electrical/outputs/nav[0]", 24.0);
    setprop("/systems/electrical/outputs/nav[1]", 24.0);
    setprop("/systems/electrical/outputs/dme", 24.0);
    setprop("/systems/electrical/outputs/adf", 24.0);
    setprop("/systems/electrical/outputs/transponder", 24.0);
    setprop("/systems/electrical/outputs/instrument-lights", 24.0);
    setprop("/systems/electrical/outputs/gps", 24.0);

    setprop("/instrumentation/clock/flight-meter-hour",0);
}

setlistener("/sim/signals/fdm-initialized", func {
    fake_electrical();
    setprop("/fdm/jsbsim/instrumentation/gas-pressure-psf", -1);
});
