###############################################################################
## $Id$
##
## Nasal module for dual control over the multiplayer network.
##
##  Copyright (C) 2007 - 2008  Anders Gidenstam  (anders(at)gidenstam.org)
##  This file is licensed under the GPL license version 2 or later.
##
###############################################################################

## MP properties
var lat_mpp     = "position/latitude-deg";
var lon_mpp     = "position/longitude-deg";
var alt_mpp     = "position/altitude-ft";
var heading_mpp = "orientation/true-heading-deg";
var pitch_mpp   = "orientation/pitch-deg";
var roll_mpp    = "orientation/roll-deg";

###############################################################################
# Utility classes

############################################################
# Translate a property into another.
#  Factor and offsets are only used for numeric values.
#   src    - source      : property node
#   dest   - destination : property node
#   factor -             : double
#   offset -             : double
var Translator = {};
Translator.new = func (src = nil, dest = nil, factor = 1, offset = 0) {
  obj = { parents   : [Translator],
          src       : src,
          dest      : dest,
          factor    : factor,
          offset    : offset };
  if (obj.src == nil or obj.dest == nil) {
    print("Translator[");
    print("  ", debug.string(obj.src));
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
Translator.update = func () {
  var v = me.src.getValue();
  if (is_num(v)) {
    me.dest.setValue(me.factor * v + me.offset);
  } else {
    if (typeof(v) == "scalar")
      me.dest.setValue(v);
  }
}

############################################################
# Detects flanks on two insignals encoded in a property.
# - positive signal up/down flank
# - negative signal up/down flank
#   n                 - source : property node
#   on_positive_flank - action : func (v)
#   on_negative_flank - action : func (v)
var EdgeTrigger = {};
EdgeTrigger.new = func (n, on_positive_flank, on_negative_flank) {
  obj = { parents   : [EdgeTrigger],
          old       : 0,
          node      : n, 
          pos_flank : on_positive_flank,
          neg_flank : on_negative_flank };
  if (obj.node == nil) {
    print("EdgeTrigger[");
    print("  ", debug.string(obj.node));
    print("]");
  }
  return obj;
}
EdgeTrigger.update = func {
  # NOTE: float MP properties get interpolated.
  #       This detector relies on that steady state is reached between
  #       flanks.
  var val = me.node.getValue();
  if (!is_num(val)) return;
  if (me.old == 1) {
    if (val < me.old) {
      me.pos_flank(0);
    }
  } elsif (me.old == 0) {
    if (val > me.old) {
      me.pos_flank(1);
    } elsif (val < me.old) {
      me.neg_flank(1);
    }
  } elsif (me.old == -1) {
    if (val > me.old) {
      me.neg_flank(0);
    }
  }
  me.old = val;
}

############################################################
# StableTrigger: Triggers an action when a MPP property
#                becomes stable (i.e. doesn't change for
#                MIN_STABLE seconds).
#   src     - MP prop : property node
#   action  - action to take when the value becomes stable : [func(v)]
# An action is triggered when value has stabilized.
var StableTrigger = {};
StableTrigger.new = func (src, action) {
  obj = { parents      : [StableTrigger],
          src          : src,
          action       : action,
          old          : 0,
          stable_since : 0,
          wait         : 0,
          MIN_STABLE   : 0.01 };
  # Error checking.
  var bad = (obj.src == nil) or (action = nil);

  if (bad) {
    print("StableTrigger[");
    print("  ", debug.string(obj.src));
    print("  ", debug.string(obj.action));
    print("]");
  }

  return obj;
}
StableTrigger.update = func () {
  var v   = me.src.getValue();
  if (!is_num(v)) return;
  var t = getprop("/sim/time/elapsed-sec"); # NOTE: simulated time.

  if ((me.old == v) and
      ((t - me.stable_since) > me.MIN_STABLE) and (me.wait == 1)) {
    # Trigger action.
    me.action(v);

    me.wait = 0;
  } elsif (me.old == v) {
    # Wait. This is either before the signal is stable or after the action. 
  } else {
    me.stable_since = t;
    me.wait         = 1;
    me.old          = me.src.getValue();
  }
}

############################################################
# Selects the most recent value of two properties.
#   src1      -  : property node
#   src2      -  : property node
#   dest      -  : property node
#   threshold -  : double
var MostRecentSelector = {};
MostRecentSelector.new = func (src1, src2, dest, threshold) {
  obj = { parents   : [MostRecentSelector],
          old1      : 0,
          old2      : 0,
          src1      : src1,
          src2      : src2,
          dest      : dest,
          thres     : threshold };
  if (obj.src1 == nil or obj.src2 == nil or obj.dest == nil) {
    print("MostRecentSelector[");
    print("  ", debug.string(obj.src1));
    print("  ", debug.string(obj.src2));
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
MostRecentSelector.update = func {
  var v1 = me.src1.getValue();
  var v2 = me.src2.getValue();
  if (!is_num(v1) and !is_num(v2)) return;
  elsif (!is_num(v1)) me.dest.setValue(v2);
  elsif (!is_num(v2)) me.dest.setValue(v1);
  else {
      if (abs (v2 - me.old2) > me.thres) {
          me.old2 = v2;
          me.dest.setValue(me.old2);
      }
      if (abs (v1 - me.old1) > me.thres) {
          me.old1 = v1;
          me.dest.setValue(me.old1);
      }
  }
}

############################################################
# Adds two input properties.
#   src1      -  : property node
#   src2      -  : property node
#   dest      -  : property node
var Adder = {};
Adder.new = func (src1, src2, dest) {
  obj = { parents : [DeltaAccumulator],
          src1    : src1,
          src2    : src2,
          dest    : dest };
  if (obj.src1 == nil or obj.src2 == nil or obj.dest == nil) {
    print("Adder[");
    print("  ", debug.string(obj.src1));
    print("  ", debug.string(obj.src2));
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
Adder.update = func () {
  var v1 = me.src1.getValue();
  var v2 = me.src2.getValue();
  if (!is_num(v1) or !is_num(v2)) return;
  me.dest.setValue(v1 + v2);
}

############################################################
# Adds the delta of src to dest.
#   src       -  : property node
#   dest      -  : property node
var DeltaAdder = {};
DeltaAdder.new = func (src, dest) {
  obj = { parents : [DeltaAdder],
          old     : 0,
          src     : src,
          dest    : dest };
  if (obj.src == nil or obj.dest == nil) {
    print("DeltaAdder[", debug.string(obj.src), ", ",
          debug.string(obj.dest), "]");
  }

  return obj;
}
DeltaAdder.update = func () {
  var v = me.src.getValue();
  if (!is_num(v)) return;
  me.dest.setValue((v - me.old) + me.dest.getValue());
  me.old = v;
}

############################################################
# Switch encoder: Encodes upto 32 boolean properties in one
# int property.
#   inputs    - list of property nodes
#   dest      - where the bitmask is stored : property node
var SwitchEncoder = {};
SwitchEncoder.new = func (inputs, dest) {
  obj = { parents : [SwitchEncoder],
          inputs  : inputs,
          dest    : dest };
  # Error checking.
  var bad = (obj.dest == nil);
  foreach (i; inputs) {
    if (i == nil) { bad = 1; }
  }

  if (bad) {
    print("SwitchEncoder[");
    foreach (i; inputs) {
      print("  ", debug.string(i));
    }
    print("  ", debug.string(obj.dest));
    print("]");
  }

  return obj;
}
SwitchEncoder.update = func () {
  var v = 0;
  var b = 1;
  forindex (i; me.inputs) {
    if (me.inputs[i].getBoolValue()) {
      v = v + b;
    }
    b *= 2;
  }
  me.dest.setIntValue(v);
}

############################################################
# Switch decoder: Decodes a bitmask in an int property.
#   src     -                 : property node
#   actions - list of actions : [func(b)]
# Actions are triggered when their input bit change.
# Due to interpolation the decoder needs to wait for a
# stable input value.
var SwitchDecoder = {};
SwitchDecoder.new = func (src, actions) {
  obj = { parents : [SwitchDecoder],
          wait         : 0,
          old          : 0,
          old_stable   : 0,
          stable_since : 0,
          reset        : 1,
          src          : src,
          actions      : actions,
          MIN_STABLE   : 0.1 };
  # Error checking.
  var bad = (obj.src == nil);
  foreach (a; obj.actions) {
    if (a == nil) { bad = 1; }
  }
  
  if (bad) {
    print("SwitchDecoder[");
    print("  ", debug.string(obj.src));
    foreach (a; obj.actions) {
      print("  ", debug.string(a));
    }
    print("]");
  }

  return obj;
}
SwitchDecoder.update = func () {
  var t = getprop("/sim/time/elapsed-sec"); # NOTE: simulated time.
  var v = me.src.getValue();
  if (!is_num(v)) return;

  if ((me.old == v) and ((t - me.stable_since) > me.MIN_STABLE) and
      (me.wait == 1)) {
    var ov = me.old_stable;
# Use this to improve.
#<cptf> here's the boring version:  var bittest = func(u, b) { while (b) { u = int(u / 2); b -= 1; } u != int(u / 2) * 2; }
    forindex (i; me.actions) {
      var m  = math.mod(v, 2);
      var om = math.mod(ov, 2);
      if ((m != om or me.reset)) { me.actions[i](m?1:0); }
      v  = (v - m)/2;
      ov = (ov - om)/2;
    }
    me.old_stable = me.src.getValue();
    me.wait  = 0;
    me.reset = 0;
  } elsif (me.old == v) {
    # Wait. This is either before the bitmask is stable or after
    # it has been processed. 
  } else {
    me.stable_since = t;
    me.wait         = 1;
    me.old          = me.src.getValue();
  }
}

############################################################
# Time division multiplexing encoder: Transmits a list of
# properties over a MP enabled string property.
#   inputs  - input properties : [property node]
#   dest    - MP string prop   : property node
# Note: TDM can have high latency so it is best used for
# non-time critical properties.
var TDMEncoder = {};
TDMEncoder.new = func (inputs, dest) {
  obj = { parents   : [TDMEncoder],
          inputs    : inputs,
          channel   : MessageChannel.new(dest,
                                         func (msg) {
                                           print("This should not happen!");
                                         }),
          MIN_INT   : 0.25,
          last_time : 0,
          next_item : 0,
          old       : [] };
  # Error checking.
  var bad = (dest == nil) or (obj.channel == nil);
  foreach (i; inputs) {
    if (i == nil) { bad = 1; }
  }

  if (bad) {
    print("TDMEncoder[");
    foreach (i; inputs) {
      print("  ", debug.string(i));
    }
    print("  ", debug.string(dest));
    print("]");
  }

  setsize(obj.old, size(obj.inputs));

  return obj;
}
TDMEncoder.update = func () {
  var t = getprop("/sim/time/elapsed-sec"); # NOTE: simulated time.
  if (t > me.last_time + me.MIN_INT) {
    var n = size(me.inputs);
    while (1) {
      var v = me.inputs[me.next_item].getValue();

      if ((n <= 0) or (me.old[me.next_item] != v)) {
        # Set the MP properties to send the next item.
        me.channel.send(Binary.encodeByte(me.next_item) ~
                        Binary.encodeDouble(v));

        me.old[me.next_item] = v;

        me.last_time = t;
        me.next_item += 1;
        if (me.next_item >= size(me.inputs)) { me.next_item = 0; }
        return;
      } else {
        # Search for changed property.
        n -= 1;
        me.next_item += 1;
        if (me.next_item >= size(me.inputs)) { me.next_item = 0; }
      }         
    }
  }
}

############################################################
# Time division multiplexing decoder: Receives a list of
# properties over a MP enabled string property.
#   src     - MP string prop  : property node
#   actions - list of actions : [func(v)]
# An action is triggered when its value is received.
# Note: TDM can have high latency so it is best used for
# non-time critical properties.
var TDMDecoder = {};
TDMDecoder.new = func (src, actions) {
  obj = { parents      : [TDMDecoder],
          actions      : actions };
  obj.channel = MessageChannel.new(src,
                                   func (msg) {
                                     obj.process(msg);
                                   });

  # Error checking.
  var bad = (src == nil) or (obj.channel == nil);
  foreach (a; actions) {
    if (a == nil) { bad = 1; }
  }

  if (bad) {
    print("TDMDecoder[");
    print("  ", debug.string(src));
    foreach (a; actions) {
      print("  ", debug.string(a));
    }
    print("]");
  }

  return obj;
}
TDMDecoder.process = func (msg) {
  var v1 = Binary.decodeByte(msg);
  var v2 = Binary.decodeDouble(substr(msg, 1));
  # Trigger action.
  me.actions[v1](v2);
}
TDMDecoder.update = func {
  me.channel.update();
}

###############################################################################

var is_num = func (v) {
    return num(v) != nil;
} 

###############################################################################

############################################################
# Detects incoming messages encoded in a string property.
#   n       - MP source : property node
#   process - action    : func (v)
# NOTE: The same object is seldom used for both sending and receiving.
var MessageChannel = {};
MessageChannel.new = func (n = nil, process = nil) {
  obj = { parents     : [MessageChannel],
          node        : n, 
          process_msg : process,
          old         : "" };
  return obj;
}
MessageChannel.update = func {
  if (me.node == nil) return;

  var msg = me.node.getValue();
  if (!streq(typeof(msg), "scalar")) return;

  if ((me.process_msg != nil) and
      !streq(msg, "") and
      !streq(msg, me.old)) {
    me.process_msg(msg);
    me.old = msg;
  }
}
MessageChannel.send = func (msg) {
  me.node.setValue(msg);
}

############################################################
# Broadcast primitive using a MP enabled string property.
#   mpp_path - MP property path                : string
#   process  - action when receiving a message : func (n, msg)
#              n is the base node of the sender
var BroadcastChannel = {};
BroadcastChannel.new = func (mpp_path, process) {
  obj = { parents     : [BroadcastChannel],
          mpp_path    : mpp_path,
          send_node   : props.globals.getNode(mpp_path, 1), 
          process_msg : process,
          send_buf    : [],
          last_send   : 0,
          peers       : {},
          loopid      : 0,
          PERIOD      : 1.3,
          last_time   : 0.0,
          SEND_TIME   : 0.2 };
  if (obj.send_node == nil) {
    print("BroadcastChannel[");
    print("  ", debug.string(obj));
    print("]");
  }
  settimer(func { obj._loop_(obj.loopid); }, 0, 1);
  print("BroadcastChannel[" ~ obj.mpp_path ~ "] ...  started.");
  return obj;
}
BroadcastChannel.send = func (msg) {
  var t = getprop("/sim/time/elapsed-sec");
  if (((t - me.last_send) > me.SEND_TIME) and (size(me.send_buf) == 0)) {
    me.send_node.setValue(msg);
    me.send_time = t;
  } else {
    append(me.send_buf, msg);
  }  
}
BroadcastChannel.update = func {
  var t = getprop("/sim/time/elapsed-sec");
  var process_msg = me.process_msg;

  # Handled join/leave. This is done more seldom.
  if ((t - me.last_time) > me.PERIOD) {
    var mpplayers =
      props.globals.getNode("/ai/models").getChildren("multiplayer");
    foreach (pilot; mpplayers) {
      if ((pilot.getChild("valid") != nil) and
          pilot.getChild("valid").getValue()) {
        if (me.peers[pilot.getIndex()] == nil) {
          me.peers[pilot.getIndex()] =
            MessageChannel.new(pilot.getNode(me.mpp_path),
                               func(msg) {
#                                 print("BroadcastChannel: processing " ~ msg);
                                 process_msg(pilot, msg);
                               });
        }
      } else {
        delete(me.peers, pilot.getIndex());
      }
    }
    me.last_time = t;
  }
  # Process new messages.
  foreach (w; keys(me.peers)) {
    if (me.peers[w] != nil) me.peers[w].update();
  }
  # Check send buffer.
  if (((t - me.last_send) > me.SEND_TIME) and (size(me.send_buf) > 0)) {
    me.send_node.setValue(me.send_buf[0]);
    me.send_buf = subvec(me.send_buf, 1);
    me.last_send = t;
  }
}
BroadcastChannel.die = func {
  me.loopid += 1;
  print("BroadcastChannel[" ~ me.mpp_path ~ "] ...  destroyed.");
}
BroadcastChannel._loop_ = func(id) {
  id == me.loopid or return;
  me.update();
  settimer(func { me._loop_(id); }, 0, 1);
}

############################################################
# NOTE: MP is picky about what it sends in a string propery.
#       Encode 7 bits as a printable 8 bit character.
var Binary = {};
Binary.TWOTO31 = 2147483648;
Binary.TWOTO32 = 4294967296;
Binary.encodeInt = func (int) {
  var bf = bits.buf(5);
  if (int < 0) int += Binary.TWOTO32;
  var r = int;
  for (var i = 0; i < 5; i += 1) {
    var c = math.mod(r, 128);
    bf[4-i] = c + 65;
    r = (r - c)/128;
  }
  return bf;
}
Binary.decodeInt = func (str) {
  var v = 0;
  var b = 1;
  for (var i = 0; i < 5; i += 1) {
    v += (str[4-i] - 65) * b;
    b *= 128;
  }
  if (v / Binary.TWOTO31 >= 1) v -= Binary.TWOTO32;
  return int(v);
}
# NOTE: This encodes a 7 bit byte.
Binary.encodeByte = func (int) {
  var bf = bits.buf(1);
  if (int < 0) int += 128;
  bf[0] = math.mod(int, 128) + 65;
  return bf;
}
Binary.decodeByte = func (str) {
  var v = str[0] - 65;
  if (v / 64 >= 1) v -= 128;
  return int(v);
}
# NOTE: This can neither handle huge values nor really tiny.
Binary.encodeDouble = func (d) {
  return Binary.encodeInt(int(d)) ~
         Binary.encodeInt((d - int(d)) * Binary.TWOTO31);
}
Binary.decodeDouble = func (str) {
  return Binary.decodeInt(substr(str, 0)) +
         Binary.decodeInt(substr(str, 5)) / Binary.TWOTO31;
}
Binary.encodeCoord = func (coord) {
  return Binary.encodeDouble(coord.lat()) ~
         Binary.encodeDouble(coord.lon()) ~
         Binary.encodeDouble(coord.alt());
}
Binary.decodeCoord = func (str) {
  var coord = geo.aircraft_position();
  coord.set_latlon(Binary.decodeDouble(substr(str, 0)),
                   Binary.decodeDouble(substr(str, 10)),
                   Binary.decodeDouble(substr(str, 20)));
  return coord;
}
###############################################################################
