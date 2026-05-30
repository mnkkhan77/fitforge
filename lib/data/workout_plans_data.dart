import '../models/workout_day.dart';

const WorkoutPlan plan5Day = WorkoutPlan(
  key: "5day",
  label: "5-Day Plan (2 Rest Days)",
  days: [
    WorkoutDay(day:"Monday",    label:"Cardio + Core",    focus:"Warm-up & Cardio",          exerciseIds:[17,16,18,10,14], isRest:false),
    WorkoutDay(day:"Tuesday",   label:"Upper Body Push",  focus:"Chest, Shoulders & Triceps", exerciseIds:[3,4,13,1,16],   isRest:false),
    WorkoutDay(day:"Wednesday", label:"Legs + Glutes",    focus:"Lower Body Power",           exerciseIds:[7,8,9,16,10],   isRest:false),
    WorkoutDay(day:"Thursday",  label:"Rest Day",         focus:"Active Recovery",            exerciseIds:[],              isRest:true),
    WorkoutDay(day:"Friday",    label:"Upper Body Pull",  focus:"Back & Biceps",              exerciseIds:[12,22,24,13,10],isRest:false),
    WorkoutDay(day:"Saturday",  label:"Full Body HIIT",   focus:"Total Burn",                 exerciseIds:[11,16,18,8,3,14],isRest:false),
    WorkoutDay(day:"Sunday",    label:"Complete Rest",    focus:"Recovery",                   exerciseIds:[],              isRest:true),
  ],
);

const WorkoutPlan plan7Day = WorkoutPlan(
  key: "7day",
  label: "7-Day Plan (No Full Rest Days)",
  days: [
    WorkoutDay(day:"Monday",    label:"Cardio Kickoff",     focus:"Running + Cardio",               exerciseIds:[17,16,18,10],    isRest:false),
    WorkoutDay(day:"Tuesday",   label:"Push Day",           focus:"Chest, Shoulders, Triceps",      exerciseIds:[3,4,5,13,1],     isRest:false),
    WorkoutDay(day:"Wednesday", label:"Leg Day",            focus:"Quads, Glutes, Hamstrings",      exerciseIds:[7,8,9,16,10],    isRest:false),
    WorkoutDay(day:"Thursday",  label:"Active Recovery",   focus:"Light Cardio + Core",            exerciseIds:[16,10,14,18],    isRest:false),
    WorkoutDay(day:"Friday",    label:"Pull Day",           focus:"Back & Biceps",                  exerciseIds:[12,22,24,10],    isRest:false),
    WorkoutDay(day:"Saturday",  label:"Full Body Blast",   focus:"Compound Movements",             exerciseIds:[11,16,8,3,12,10],isRest:false),
    WorkoutDay(day:"Sunday",    label:"Stretch & Mobility",focus:"Recovery & Flexibility",          exerciseIds:[10,14,16],       isRest:false),
  ],
);
