###############################################################################
## $Id$
##
## Nasal for main pilot for dual control over the multiplayer network.
##
##  Copyright (C) 2007  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license.
##
###############################################################################

# Renaming (almost :)
var DCT = dual_control_tools;
# NOTE: By loading the aircraft specific dual control module
#       as <aircraft_dual_control> this file is generic. 
var ADC = aircraft_dual_control;

######################################################################
# Connect new copilot
var process_data = 0;

var connect = func (copilot) {
  # Tweak MP/AI filters
  copilot.getNode("controls/allow-extrapolation").setBoolValue(0);
  copilot.getNode("controls/lag-adjust-system-speed").setValue(5);

  process_data = ADC.pilot_connect_copilot(copilot);

  print("Dual control ... copilot connected.");
  setprop("/sim/messages/copilot", "Hi.");
}

######################################################################
# Main loop singleton class.
var main = {
  init : func {
    me.loopid = 0;
    me.active = 0;
    setlistener("/ai/models/model-added", func {
      settimer(func { me.activate(); }, 2);
    });
    settimer(func { me.activate(); }, 5);
    print("Pilot dual control ... initialized");
  },
  reset : func {
    me.loopid += 1;
    me._loop_(me.loopid);
  },
  activate : func {
    if (!me.active) {
      me.reset();
    }
  },
  update : func {
    var mpplayers =
      props.globals.getNode("/ai/models").getChildren("multiplayer");
    var r_callsign = getprop("/sim/remote/pilot-callsign");

    foreach (copilot; mpplayers) {
      if ((copilot.getChild("valid").getValue()) and
          (copilot.getChild("callsign") != nil) and
          (copilot.getChild("callsign").getValue() == r_callsign)) {

        if (me.active == 0) {
          # Note: sim/model/ac-type is set by the model XML file. 
          if ((copilot.getNode("sim/model/ac-type") != nil) and
              (copilot.getNode("sim/model/ac-type").getValue() ==
               ADC.copilot_type)) {
            connect(copilot);
            me.active = 1;
          } else {
            print("Dual control ... copilot rejected - wrong aircraft type.");
            me.loopid += 1;
            return;
          }
        }

        # Mess with the MP filters. Highly experimental.
        if (copilot.getNode("controls/lag-time-offset") != nil) {
          var v = copilot.getNode("controls/lag-time-offset").getValue();
          copilot.getNode("controls/lag-time-offset").setValue(0.97 * v);
        }

        foreach (w; process_data) {
          w.update();
        }
        return;
      }
    }
    if (me.active) {
      print("Dual control ... copilot disconnected.");
      ADC.pilot_disconnect_copilot();
    }
    me.loopid += 1;
    me.active = 0;
  },
  _loop_ : func(id) {
    id == me.loopid or return;
    me.update();
    settimer(func { me._loop_(id); }, 0);
  }
};

######################################################################
# Initialization.
setlistener("/sim/signals/fdm-initialized", func {
  main.init();
});
