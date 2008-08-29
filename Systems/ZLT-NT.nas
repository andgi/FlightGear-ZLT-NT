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
var static_trim_p = "/fdm/jsbsim/fcs/static-trim-cmd-norm";
var ballonet_cmd_p =
    ["/fdm/jsbsim/fcs/ballonet-inflation-cmd-norm[0]",
     "/fdm/jsbsim/fcs/ballonet-inflation-cmd-norm[1]"];
var weight_on_gear_p = "/fdm/jsbsim/forces/fbz-gear-lbs";
var ballast_p = "/fdm/jsbsim/inertia/pointmass-weight-lbs";

var print_wow = func {
  gui.popupTip("Current weight on gear " ~
               -getprop(weight_on_gear_p) ~ " lbs.");
}

var weighoff = func {
  var wow = getprop(weight_on_gear_p);
  gui.popupTip("Weigh-off to 50% in progress. " ~
               "Current weight " ~ -wow ~ " lbs.");
  var cont = getprop(ballast_p);
  var new  = cont + 0.50 * wow;
  interpolate(ballast_p,
              (new > 0 ? new : 0.0),
              10);
}

var auto_weighoff = func {
    var v = getprop(ballast_p) +
        getprop("/fdm/jsbsim/static-condition/net-lift-lbs");

    interpolate(ballast_p,
                (v > 0 ? 700.0 + v : 0),
                0.5);
}

var initial_weighoff = func {
    # Set initial static condition.
    # Finding the right static condition at initialization time is tricky.
    auto_weighoff();
    settimer(auto_weighoff, 0.25);
    settimer(auto_weighoff, 1.0);
}

var mp_mast_carriers =
    ["Aircraft/Crash_tender/Models/crash_tender.xml",
     "Aircraft/snowplow/Models/Snowplow.xml"];

var init_all = func(reinit=0) {
    setprop(static_trim_p, 0.3);
    setprop(ballonet_cmd_p[0], 1.0);
    setprop(ballonet_cmd_p[1], 1.0);
    initial_weighoff();

    fake_electrical();

    settimer(func {
        # Add some AI moorings.
        mooring.add_ai_mooring(props.globals.getNode("/ai/models/carrier[0]"),
                               160.0);
        mooring.add_ai_mooring(props.globals.getNode("/ai/models/carrier[1]"),
                               160.0);
        mooring.add_ai_mooring(props.globals.getNode("/ai/models/carrier[2]"),
                               160.0);
        setlistener(props.globals.getNode("/ai/models/model-added", 1),
                    func (path) {
                        var node = props.globals.getNode(path.getValue());
                        if (nil == node.getNode("sim/model/path")) return;
                        var model = node.getNode("sim/model/path").getValue();
                        foreach (c; mp_mast_carriers) {
                            if (model == c) {
                                mooring.add_ai_mooring(node, 11.8);
                                print("Added: " ~ path.getValue());
                                return;
                            }
                        }
                    });
        setlistener(props.globals.getNode("/ai/models/model-removed"),
                    func (path) {
                        var node = props.globals.getNode(path.getValue());
                        mooring.remove_ai_mooring(node);
                        #print("Removed: " ~ path.getValue());
                    });
    }, 1.0);
}

setlistener("/sim/signals/fdm-initialized", func {
    init_all();
    setlistener("/sim/signals/reinit", func(reinit) {
        if (!reinit.getValue()) {
            init_all(reinit=1);
        }
    });
});

###############################################################################
# controls.nas overrides.

engine_swivel_p = ["fdm/jsbsim/fcs/side-engine-swivel-cmd-norm[0]",
                   "fdm/jsbsim/fcs/side-engine-swivel-cmd-norm[1]",
                   "fdm/jsbsim/fcs/rear-engine-swivel-cmd-norm[0]"];

# The flap control controls side engine swivel.
controls.flapsDown = func(step) {
    if (!step) return;
    # The engines are swiveled together for now.
    var v = getprop(engine_swivel_p[0]) + (step > 0 ? -0.1 : 0.1);
    if (v < 0) v = 0;
    if (v > 1) v = 1;
    setprop(engine_swivel_p[0], v);
    setprop(engine_swivel_p[1], v);
    gui.popupTip("Side engine swivel " ~ int(120*v) ~ " deg.");
}

# Landing gear control controls rear engine swivel
controls.gearDown = func(step) {
    if (!step) return;
    var v = getprop(engine_swivel_p[2]) + (step > 0 ? 1.0 : -1.0);
    if (v < 0) v = 0;
    if (v > 1) v = 1;
    setprop(engine_swivel_p[2], v);
    gui.popupTip("Aft engine swivel " ~ int(90*v) ~ " deg.");
}

# Ballonet control
var step_ballonet_cmd = func(n, d) {
    var p = ballonet_cmd_p[n];
    var t = getprop(p) + d;
    if (t >  1.0) { t =  1.0; }
    if (t < -1.0) { t = -1.0; }
    setprop(p, t);
    gui.popupTip((n ? "Aft" : "Forward") ~ " ballonet " ~
                 (t <= 0 ? ("valve " ~ int(-100*t + 0.005) ~ "% open.")
                  : ("blower " ~ int(100*t + 0.005) ~ "%.")));
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
        me.left.add(static_trim_p);
        me.left.add("/fdm/jsbsim/mooring/total-distance-ft");
        # Engines
        me.right.add("/fdm/jsbsim/fcs/etc/propeller-speed-cmd-rpm[0]",
                     "/engines/engine[0]/thruster/rpm",
                     "/fdm/jsbsim/propulsion/engine[0]/blade-angle",
                     "/fdm/jsbsim/fcs/throttle-pos-norm[0]");
        me.right.add("/fdm/jsbsim/fcs/etc/propeller-speed-cmd-rpm[1]",
                     "/engines/engine[1]/thruster/rpm",
                     "/fdm/jsbsim/propulsion/engine[1]/blade-angle",
                     "/fdm/jsbsim/fcs/throttle-pos-norm[1]");
        me.right.add("/fdm/jsbsim/fcs/etc/propeller-speed-cmd-rpm[2]",
                     "/engines/engine[2]/thruster/rpm",
                     "/fdm/jsbsim/propulsion/engine[2]/blade-angle",
                     "/fdm/jsbsim/fcs/throttle-pos-norm[2]");
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
###############################################################################

###########################################################################
## MP integration of user's fixed local mooring locations.
## NOTE: Should this be here or elsewhere?
settimer(func { mp_network_init(1); }, 0.1);


