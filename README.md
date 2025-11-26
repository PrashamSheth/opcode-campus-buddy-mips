# OP-CODE: Campus Buddy in MIPS Assembly

A personalised student life manager written entirely in MIPS assembly. For a chosen day and the current time, it shows:
- the class schedule and how long until the next class, with advice on where to go in the meantime;
- the SGPA needed to reach a target CGPA, with a graduation progress bar;
- an attendance planner against the 80% cutoff;
- activity and study-time suggestions personalised from the student ID.

## Coursework

Assignment 2 for **Foundations of Computer Systems (CS2011)**, Semester 5, Plaksha University.

## Features

| Feature | How it works |
|---|---|
| Daily schedule | Day-indexed tables of class lines. The current time (HHMM) is converted to minutes, and the program finds the next class and the time remaining |
| Where to go | 90 minutes or more until the next class: hostel room or library. 30-89 minutes: library. Under 30 minutes: canteen, staying close to class |
| Academic progress | Required SGPA = (target CGPA x (done + this semester's credits) - current CGPA x done credits) / this semester's credits, computed with single-precision floating-point instructions. Progress bars show the share of the 180 degree credits completed now and after this semester |
| Attendance planner | For each subject: current percentage, then classes needed = ceil(0.80 x (held + 10 remaining)) - attended. The ceiling uses integer arithmetic, (80 x total + 99) / 100. It reports whether the cutoff is already met, can still be met, or cannot be met |
| Personalisation | Campus personality = (ID >> 2) mod 4 = 2, so it suggests a quick sports session or walk. Study pattern = (sum of ID digits) mod 5 = 0, so it suggests morning study |
| Menu | Options 1-4 each show only that section (each section is a subroutine called with `jal` and returning with `jr $ra`). Option 5 goes back to choosing the day |

## Sample output (Monday, 10:15)

```
Student ID: 20230026 | Day: Monday | Time: 10:15

TODAY'S SCHEDULE:
9:00 - 10:30 Deep Learning (Room 2201)
10:30 - 11:30 Engineering Mechanics (Room 1104)
2:00 - 3:30 Foundations of Computer Systems (Room 2201)
3:30 - 4:30 Sensing and Actuation (Room 2203)

Next class in 0 h 15 min: 10:30 - 11:30 Engineering Mechanics (Room 1104)
Where to go: grab something at the canteen and stay close to class.

ACADEMIC OVERVIEW:
Current CGPA: 8.15 | Credits: 81/180
Target CGPA: 8.5 | Required this semester: 9.68
Graduation progress now:        [#########...........] 45%
After this semester (if passed): [###########.........] 58%

ATTENDANCE PLANNER:
Deep Learning  36/48 (75%) (ATTENDANCE CRITERIA WILL NOT BE FULFILLED)
Eng Mechanics  46/64 (71%) (ATTENDANCE CRITERIA WILL NOT BE FULFILLED)
FoCS           34/48 (70%) (ATTENDANCE CRITERIA WILL NOT BE FULFILLED)
Sensing Act    49/64 (76%) (ATTENDANCE CRITERIA WILL NOT BE FULFILLED)
Electromag     39/48 (81%) (ATTENDANCE CRITERIA FULFILLED)

SMART SUGGESTIONS:
Free Slot: Long break (11:30 - 2:00). Ideal for lunch and focused study or project work.
Activity Suggestion: Quick sports session or walk to refresh before next class.
Study Time Suggestion: Morning (6:30 - 9:00) - best for focused learning.
```

The full run is in `sample_output.txt`.

## How to run

1. Open `campus_buddy_20230026.asm` in [MARS](http://courses.missouristate.edu/kenvollmar/mars/) (or QtSpim).
2. Assemble and run.
3. Enter a day (1-6), then the current time as HHMM in 24-hour format (for example `1015`).
4. Use the menu: 1 Schedule, 2 Grades, 3 Attendance, 4 Suggestions, 5 Change day. Enter 7 at the day prompt to exit.

From the command line: `java -jar Mars4_5.jar campus_buddy_20230026.asm`

## Testing the personalisation

Change `student_id`, `current_cgpa`, `target_cgpa`, `completed_credits` or the attendance arrays in the `.data` section. The suggestions, required SGPA and attendance messages all update. For example, with 38 of 48 Deep Learning classes attended, the planner prints `Deep Learning  38/48 (79%) -> Need 9 of next 10`.

## Notes on the cleanup

- In the submitted version, choosing a single menu option (for example Schedule) fell through and printed every section again. Each section is now a subroutine, so the menu shows only what was asked for.
- Added two parts of the brief that were missing: the time remaining until the next class (with location advice), and a visual progress bar towards graduation.
- The required SGPA is printed rounded to two decimals instead of the raw float (9.681252).
- Fixed missing separators in the output (for example "8.15Credits" and "Deep Learning36/48"). Replaced a non-ASCII dash that showed up garbled in the console.
- Statements are now one per line (instead of several joined by `;`), so the file assembles in any MIPS simulator.
