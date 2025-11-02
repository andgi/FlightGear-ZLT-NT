###############################################################################
##
## Zeppelin NT-07 airship for FlightGear.
## Passenger view configuration.
##
##  Copyright (C) 2010, 2025  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license v2 or later.
##
###############################################################################

# Constraints
var carConstraint =
    walkview.makeUnionConstraint(
        [
         # Cockpit area.
         walkview.SlopingYAlignedPlane.new([19.1, -0.3, -8.85],
                                           [19.5,  0.3, -8.85]),
         # Passenger cabin.
         walkview.SlopingYAlignedPlane.new([19.5, -0.7, -9.08], 
                                           [26.4,  0.7, -9.08]),
         # Rear coach. Sit down when entering.
         walkview.ActionConstraint.new
             (walkview.SlopingYAlignedPlane.new([26.4, -0.45, -9.29], # -8.42
                                                [26.7,  0.45, -9.29]),
              func {
                  print("Seated!");
                  setprop("sim/model/crew/passenger/pose/position/limb[9]/y-deg", -90);
                  setprop("sim/model/crew/passenger/pose/position/limb[12]/y-deg", -90);
                  setprop("sim/model/crew/passenger/pose/position/limb[10]/y-deg", 90);
                  setprop("sim/model/crew/passenger/pose/position/limb[13]/y-deg", 90);
                  #walker.set_eye_height(0.82);
                  walker.set_eye_height(1.60);
              },
              func(x, y) {
                  if (x <= 0) {
                      print("Standing!");
                      walker.set_eye_height(1.65);
                      setprop("sim/model/crew/passenger/pose/position/limb[9]/y-deg", 0);
                      setprop("sim/model/crew/passenger/pose/position/limb[12]/y-deg", 0);
                      setprop("sim/model/crew/passenger/pose/position/limb[10]/y-deg", 0);
                      setprop("sim/model/crew/passenger/pose/position/limb[13]/y-deg", 0);
                  }
              })
        ]);

# ThreeDModel manager.
#   Moves a 3d model representing the crew member together with the view.
#   The position is in the main 3d coordinate system.
# CONSTRUCTOR:
#       ThreeDModel.new(name, maximumMoveValue);
#
#         name             ... Name of the view : string
#         maximumMoveValue ... Maximum movement of the view i meters : double
#
var ThreeDModelManager = {
    new : func (name, maximumMoveValue) {
        var base = props.globals.getNode("crew/" ~ name ~ "/");
        var prefix  = "position-";
        var postfix = "-m";
        var obj = { parents : [ThreeDModelManager] };
        obj.pos_m =
            [
             base.getNode(prefix ~ "X" ~ postfix),
             base.getNode(prefix ~ "Y" ~ postfix),
             base.getNode(prefix ~ "Z" ~ postfix)
            ];
        obj.maximumMoveValue = maximumMoveValue;
        base.getNode("maximum-move-m").setValue(obj.maximumMoveValue);
        postfix = "-norm";
        obj.pos_norm =
            [
             base.getNode(prefix ~ "X" ~ postfix),
             base.getNode(prefix ~ "Y" ~ postfix),
             base.getNode(prefix ~ "Z" ~ postfix)
            ];
        postfix = "-offset-deg";
        obj.orientation_deg =
            [
             base.getNode("heading" ~ postfix),
             base.getNode("pitch" ~ postfix),
            ];
        return obj;
    },
    update : func (walker) {
        # Position.
        var pos = walker.get_pos();
        me.pos_m[0].setValue(pos[0]);
        me.pos_m[1].setValue(pos[1]);
        me.pos_m[2].setValue(pos[2] - walker.get_eye_height());
        # Normalized position.
        me.pos_norm[0].setValue(pos[0]/me.maximumMoveValue);
        me.pos_norm[1].setValue(pos[1]/me.maximumMoveValue);
        me.pos_norm[2].setValue((pos[2] - walker.get_eye_height())/me.maximumMoveValue);
        # Orientation is not yet stored in the walker but is stored in the view.
        me.orientation_deg[0].setValue(
            props.globals.getNode("/sim/current-view/heading-offset-deg").getValue());
        me.orientation_deg[1].setValue(
            props.globals.getNode("/sim/current-view/pitch-offset-deg").getValue());
    }
};


# The view manager.
var walker =
    walkview.Walker.new("Passenger View",
                        carConstraint,
                        [ThreeDModelManager.new("passenger-view", 50.0)]);
walker.managers[0].update(walker); # Place the 3d object.
