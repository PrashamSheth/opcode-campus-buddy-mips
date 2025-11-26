# campus_buddy_20230026.asm
# OP-CODE: Your Personalized Student Life Manager
# Student ID: 20230026
#
# A campus dashboard written in MIPS assembly (MARS / SPIM). For a chosen day and
# current time it shows the class schedule, time until the next class, academic
# progress (required SGPA and a graduation progress bar), an attendance planner
# and personalised suggestions derived from the student ID.
#
# Personalisation from the student ID:
#   campus personality  = (ID >> 2) mod 4          -> 2 (active: sports / walk)
#   study time pattern  = (sum of ID digits) mod 5 -> 0 (morning)

.data
student_id:           .word  20230026
current_cgpa:         .float 8.15
target_cgpa:          .float 8.50
completed_credits:    .word  81
semester_credits:     .word  24
degree_total_credits: .word  180

day_index:    .word 0
current_time: .word 0          # minutes since midnight

# --- Day names ---
title:         .asciiz "=== CAMPUS BUDDY ===\n"
student_label: .asciiz "Student ID: "
day_label:     .asciiz " | Day: "
day_mon: .asciiz "Monday"
day_tue: .asciiz "Tuesday"
day_wed: .asciiz "Wednesday"
day_thu: .asciiz "Thursday"
day_fri: .asciiz "Friday"
day_sat: .asciiz "Saturday"
day_names_ptrs: .word day_mon, day_tue, day_wed, day_thu, day_fri, day_sat
day_list_header: .asciiz "\nSelect a day (1-6) or 7 to Exit:\n1: Monday\n2: Tuesday\n3: Wednesday\n4: Thursday\n5: Friday\n6: Saturday\n7: Exit Program\nYour choice: "
time_prompt:   .asciiz "Enter the current time in 24-hour HHMM format (e.g. 1015): "
invalid_day:   .asciiz "Invalid selection. Please enter a number between 1 and 7.\n"
invalid_time:  .asciiz "Invalid time. Please enter HHMM between 0000 and 2359.\n"
exit_program:  .asciiz "Exiting program...\n"
time_label:    .asciiz " | Time: "
colon:         .asciiz ":"
zero_str:      .asciiz "0"

sched_header:   .asciiz "\nTODAY'S SCHEDULE:\n"
grades_header:  .asciiz "\nACADEMIC OVERVIEW:\n"
att_header:     .asciiz "\nATTENDANCE PLANNER:\n"
suggest_header: .asciiz "\nSMART SUGGESTIONS:\n"

menu_line:       .asciiz "\nMenu: [1-Schedule] [2-Grades] [3-Attendance] [4-Suggestions] [5-Change day/Exit]\nYour choice: "
menu_reprint_1:  .asciiz "Option 1: Schedule Selected\n"
menu_reprint_2:  .asciiz "Option 2: Grades Selected\n"
menu_reprint_3:  .asciiz "Option 3: Attendance Selected\n"
menu_reprint_4:  .asciiz "Option 4: Suggestions Selected\n"
menu_return_day: .asciiz "Option 5: Returning to Day Selection...\n"
menu_invalid:    .asciiz "Invalid menu option. Please select 1-5.\n"

# --- Class schedule: count, then pointers to the class lines ---
monday_classes: .word 4, mon0, mon1, mon2, mon3
mon0: .asciiz "9:00 - 10:30 Deep Learning (Room 2201)\n"
mon1: .asciiz "10:30 - 11:30 Engineering Mechanics (Room 1104)\n"
mon2: .asciiz "2:00 - 3:30 Foundations of Computer Systems (Room 2201)\n"
mon3: .asciiz "3:30 - 4:30 Sensing and Actuation (Room 2203)\n"
tuesday_classes: .word 4, tue0, tue1, tue2, tue3
tue0: .asciiz "9:00 - 11:00 Sensing and Actuation Lab (Physics Lab)\n"
tue1: .asciiz "11:00 - 12:30 Electromagnetism (Room 2203)\n"
tue2: .asciiz "3:00 - 4:00 Sensing and Actuation (Room 2203)\n"
tue3: .asciiz "4:00 - 5:00 Narrative Twists (Room 2201)\n"
wednesday_classes: .word 4, wed0, wed1, wed2, wed3
wed0: .asciiz "9:00 - 10:30 Deep Learning (Room 2201)\n"
wed1: .asciiz "10:30 - 11:30 Engineering Mechanics (Room 1104)\n"
wed2: .asciiz "2:00 - 3:30 Foundations of Computer Systems (Room 2201)\n"
wed3: .asciiz "3:30 - 4:30 Sensing and Actuation (Room 2203)\n"
thursday_classes: .word 3, thu0, thu1, thu2
thu0: .asciiz "9:00 - 11:00 FoCS Lab (Hostel 2)\n"
thu1: .asciiz "11:00 - 12:30 Electromagnetism (Room 2203)\n"
thu2: .asciiz "4:00 - 5:00 Narrative Twists (Room 2201)\n"
friday_classes: .word 3, fri0, fri1, fri2
fri0: .asciiz "9:00 - 11:00 Deep Learning Lab (Room 2201)\n"
fri1: .asciiz "11:00 - 12:00 Engineering Mechanics (Room 1104)\n"
fri2: .asciiz "2:00 - 4:00 Engineering Mechanics Lab (Room 2203)\n"
saturday_classes: .word 1, sat0
sat0: .asciiz "11:00 - 12:00 Electromagnetism Tutorial (Room 2203)\n"
days_arrays: .word monday_classes, tuesday_classes, wednesday_classes, thursday_classes, friday_classes, saturday_classes

# Start time of each class in minutes since midnight (same order as above)
mon_starts: .word 540, 630, 840, 930
tue_starts: .word 540, 660, 900, 960
wed_starts: .word 540, 630, 840, 930
thu_starts: .word 540, 660, 960
fri_starts: .word 540, 660, 840
sat_starts: .word 660
starts_ptrs: .word mon_starts, tue_starts, wed_starts, thu_starts, fri_starts, sat_starts

next_class_str: .asciiz "Next class in "
hours_str:      .asciiz " h "
mins_str:       .asciiz " min: "
no_more_str:    .asciiz "No more classes today. Time to rest, revise or join a club activity.\n"
go_hostel_str:  .asciiz "Where to go: plenty of time - head to your hostel room or the library.\n"
go_library_str: .asciiz "Where to go: enough time for a focused session in the library.\n"
go_canteen_str: .asciiz "Where to go: grab something at the canteen and stay close to class.\n"

# --- Free slots per day ---
free_slot_mon: .asciiz "Free Slot: Long break (11:30 - 2:00). Ideal for lunch and focused study or project work.\n"
free_slot_tue: .asciiz "Free Slot: Large gap (12:30 - 3:00). Suggest quick lunch and light revision.\n"
free_slot_wed: .asciiz "Free Slot: Long break (11:30 - 2:00). Ideal for lunch and focused study or project work.\n"
free_slot_thu: .asciiz "Free Slot: Very long break (12:30 - 4:00). Use for core project work or exercise.\n"
free_slot_fri: .asciiz "Free Slot: Single 2-hour break (12:00 - 2:00). Plenty of time for lunch and a short task.\n"
free_slot_sat: .asciiz "Free Slot: Afternoon is free. Use the day for intensive study or personal time.\n"
free_slots_ptrs: .word free_slot_mon, free_slot_tue, free_slot_wed, free_slot_thu, free_slot_fri, free_slot_sat

# --- Personalised suggestions ---
pers_lib_str:     .asciiz "Activity Suggestion: Use free slot to study in Library (quiet, power outlets available).\n"
pers_canteen_str: .asciiz "Activity Suggestion: Grab a snack at the Canteen and do light revision.\n"
pers_sports_str:  .asciiz "Activity Suggestion: Quick sports session or walk to refresh before next class.\n"
pers_proj_str:    .asciiz "Activity Suggestion: Work on group project / coding in the lab during long free slot.\n"
sp_morning_str:   .asciiz "Study Time Suggestion: Morning (6:30 - 9:00) - best for focused learning.\n"
sp_afternoon_str: .asciiz "Study Time Suggestion: Afternoon (1:00 - 4:00) - good for group tasks.\n"
sp_evening_str:   .asciiz "Study Time Suggestion: Evening (6:00 - 9:00) - good for revision.\n"
sp_night_str:     .asciiz "Study Time Suggestion: Night (10:00 - 12:00) - quiet solo work.\n"
sp_default_str:   .asciiz "Study Time Suggestion: Try a mixed schedule based on class load and energy levels.\n"

# --- Attendance ---
att_crit_fulfilled:     .asciiz " (ATTENDANCE CRITERIA FULFILLED)\n"
att_crit_not_fulfilled: .asciiz " (ATTENDANCE CRITERIA WILL NOT BE FULFILLED)\n"
att_needs:              .asciiz " -> Need "
att_of_next:            .asciiz " of next "
subj_str0: .asciiz "Deep Learning  "
subj_str1: .asciiz "Eng Mechanics  "
subj_str2: .asciiz "FoCS           "
subj_str3: .asciiz "Sensing Act    "
subj_str4: .asciiz "Electromag     "
subj_ptrs: .word subj_str0, subj_str1, subj_str2, subj_str3, subj_str4
classes_held: .word 48, 64, 48, 64, 48
classes_att:  .word 36, 46, 34, 49, 39
cutoff_percent_int: .word 80
remaining_classes_assumed: .word 10

# --- Helper strings ---
str_nl: .asciiz "\n"
str_slash: .asciiz "/"
str_dot: .asciiz "."
str_space_paren: .asciiz " ("
str_percent_closeparen: .asciiz "%)"
str_curr_cgpa: .asciiz "Current CGPA: "
str_credits: .asciiz " | Credits: "
str_target_cgpa: .asciiz "Target CGPA: "
str_required_sgpa: .asciiz " | Required this semester: "
str_progress_now: .asciiz "Graduation progress now:        ["
str_progress_after: .asciiz "After this semester (if passed): ["
str_bar_close: .asciiz "] "
str_percent: .asciiz "%\n"
bar_full: .asciiz "#"
bar_empty: .asciiz "."
str_unreachable: .asciiz " (above 10: target not reachable this semester)"


.text
.globl main
main:
    la $a0, title
    li $v0, 4
    syscall

# ----------------------------------
# Day and time selection
# ----------------------------------
read_day_input:
    la $a0, day_list_header
    li $v0, 4
    syscall
    li $v0, 5
    syscall
    move $t0, $v0
    li $t1, 7
    beq $t0, $t1, exit_program_now
    blt $t0, 1, invalid_day_input
    bgt $t0, 6, invalid_day_input
    addi $t0, $t0, -1               # 0-based day index
    sw $t0, day_index
    j read_time_input

invalid_day_input:
    la $a0, invalid_day
    li $v0, 4
    syscall
    j read_day_input

read_time_input:
    la $a0, time_prompt
    li $v0, 4
    syscall
    li $v0, 5
    syscall
    move $t0, $v0                   # HHMM
    li $t1, 100
    div $t0, $t1
    mflo $t2                        # hours
    mfhi $t3                        # minutes
    bltz $t0, invalid_time_input
    bgt $t2, 23, invalid_time_input
    bgt $t3, 59, invalid_time_input
    li $t4, 60
    mult $t2, $t4
    mflo $t2
    add $t2, $t2, $t3               # minutes since midnight
    sw $t2, current_time
    j dashboard

invalid_time_input:
    la $a0, invalid_time
    li $v0, 4
    syscall
    j read_time_input

exit_program_now:
    la $a0, exit_program
    li $v0, 4
    syscall
    li $v0, 10
    syscall

# ----------------------------------
# Full dashboard: every section once
# ----------------------------------
dashboard:
    jal print_header
    jal print_schedule
    jal print_grades
    jal print_attendance
    jal print_suggestions

menu_prompt:
    la $a0, menu_line
    li $v0, 4
    syscall
    li $v0, 5
    syscall
    move $t0, $v0
    li $t1, 1
    beq $t0, $t1, menu_schedule
    li $t1, 2
    beq $t0, $t1, menu_grades
    li $t1, 3
    beq $t0, $t1, menu_attendance
    li $t1, 4
    beq $t0, $t1, menu_suggestions
    li $t1, 5
    beq $t0, $t1, menu_exit
    la $a0, menu_invalid
    li $v0, 4
    syscall
    j menu_prompt

menu_schedule:
    la $a0, menu_reprint_1
    li $v0, 4
    syscall
    jal print_schedule
    j menu_prompt
menu_grades:
    la $a0, menu_reprint_2
    li $v0, 4
    syscall
    jal print_grades
    j menu_prompt
menu_attendance:
    la $a0, menu_reprint_3
    li $v0, 4
    syscall
    jal print_attendance
    j menu_prompt
menu_suggestions:
    la $a0, menu_reprint_4
    li $v0, 4
    syscall
    jal print_suggestions
    j menu_prompt
menu_exit:
    la $a0, menu_return_day
    li $v0, 4
    syscall
    j read_day_input

# ==================================================================
# Subroutines (each returns with jr $ra; none of them calls another)
# ==================================================================

# Prints "Student ID: ... | Day: ... | Time: HH:MM"
print_header:
    la $a0, student_label
    li $v0, 4
    syscall
    lw $a0, student_id
    li $v0, 1
    syscall
    la $a0, day_label
    li $v0, 4
    syscall
    lw $t0, day_index
    la $t1, day_names_ptrs
    sll $t2, $t0, 2
    add $t1, $t1, $t2
    lw $a0, 0($t1)
    li $v0, 4
    syscall
    la $a0, time_label
    li $v0, 4
    syscall
    lw $t0, current_time
    li $t1, 60
    div $t0, $t1
    mflo $a0
    mfhi $t3
    li $v0, 1
    syscall
    la $a0, colon
    li $v0, 4
    syscall
    bge $t3, 10, header_two_digits
    la $a0, zero_str
    li $v0, 4
    syscall
header_two_digits:
    move $a0, $t3
    li $v0, 1
    syscall
    la $a0, str_nl
    li $v0, 4
    syscall
    jr $ra

# 1. Schedule, next class and where to go
print_schedule:
    la $a0, sched_header
    li $v0, 4
    syscall
    lw $t0, day_index
    sll $t0, $t0, 2
    la $t1, days_arrays
    add $t1, $t1, $t0
    lw $t2, 0($t1)                  # class table for the day
    lw $t3, 0($t2)                  # number of classes
    addi $t2, $t2, 4                # first class pointer
    li $t4, 0
sched_print_loop:
    beq $t4, $t3, sched_find_next
    sll $t5, $t4, 2
    add $t6, $t2, $t5
    lw $a0, 0($t6)
    li $v0, 4
    syscall
    addi $t4, $t4, 1
    j sched_print_loop

sched_find_next:
    la $a0, str_nl
    li $v0, 4
    syscall
    la $t1, starts_ptrs
    add $t1, $t1, $t0
    lw $t7, 0($t1)                  # start times for the day
    lw $t8, current_time
    li $t4, 0
sched_next_loop:
    beq $t4, $t3, sched_no_more
    sll $t5, $t4, 2
    add $t6, $t7, $t5
    lw $t9, 0($t6)                  # class start (minutes)
    bgt $t9, $t8, sched_found_next
    addi $t4, $t4, 1
    j sched_next_loop

sched_found_next:
    sub $t9, $t9, $t8               # minutes until the class
    la $a0, next_class_str
    li $v0, 4
    syscall
    li $t1, 60
    div $t9, $t1
    mflo $a0
    li $v0, 1
    syscall
    la $a0, hours_str
    li $v0, 4
    syscall
    mfhi $a0
    li $v0, 1
    syscall
    la $a0, mins_str
    li $v0, 4
    syscall
    add $t6, $t2, $t5
    lw $a0, 0($t6)
    li $v0, 4
    syscall
    # Location advice from the size of the gap
    bge $t9, 90, sched_go_hostel
    bge $t9, 30, sched_go_library
    la $a0, go_canteen_str
    j sched_print_go
sched_go_hostel:
    la $a0, go_hostel_str
    j sched_print_go
sched_go_library:
    la $a0, go_library_str
sched_print_go:
    li $v0, 4
    syscall
    jr $ra

sched_no_more:
    la $a0, no_more_str
    li $v0, 4
    syscall
    jr $ra

# 2. Academic overview: required SGPA and graduation progress
#    required SGPA = (target * (done + sem) - current * done) / sem
print_grades:
    li $s7, 0                       # 0 = drawing the first progress bar
    la $a0, grades_header
    li $v0, 4
    syscall
    l.s $f0, current_cgpa
    lw $t0, completed_credits
    mtc1 $t0, $f2
    cvt.s.w $f2, $f2
    mul.s $f4, $f0, $f2             # current grade points
    l.s $f6, target_cgpa
    lw $t1, semester_credits
    add $t3, $t0, $t1
    mtc1 $t3, $f8
    cvt.s.w $f8, $f8
    mul.s $f10, $f6, $f8            # target total grade points
    sub.s $f12, $f10, $f4           # grade points needed this semester
    mtc1 $t1, $f14
    cvt.s.w $f14, $f14
    div.s $f16, $f12, $f14          # required SGPA

    la $a0, str_curr_cgpa
    li $v0, 4
    syscall
    l.s $f12, current_cgpa
    li $v0, 2
    syscall
    la $a0, str_credits
    li $v0, 4
    syscall
    lw $a0, completed_credits
    li $v0, 1
    syscall
    la $a0, str_slash
    li $v0, 4
    syscall
    lw $a0, degree_total_credits
    li $v0, 1
    syscall
    la $a0, str_nl
    li $v0, 4
    syscall
    la $a0, str_target_cgpa
    li $v0, 4
    syscall
    l.s $f12, target_cgpa
    li $v0, 2
    syscall
    la $a0, str_required_sgpa
    li $v0, 4
    syscall
    # print required SGPA rounded to 2 decimals: (int)(x * 100 + 0.5) / 100
    li $t4, 100
    mtc1 $t4, $f18
    cvt.s.w $f18, $f18
    mul.s $f20, $f16, $f18
    cvt.w.s $f20, $f20
    mfc1 $t5, $f20
    div $t5, $t4
    mflo $a0
    li $v0, 1
    syscall
    la $a0, str_dot
    li $v0, 4
    syscall
    mfhi $t6
    bge $t6, 10, grades_two_digits
    la $a0, zero_str
    li $v0, 4
    syscall
grades_two_digits:
    move $a0, $t6
    li $v0, 1
    syscall
    li $t7, 1000                    # SGPA scale is 0-10, i.e. 1000 in hundredths
    ble $t5, $t7, grades_reachable
    la $a0, str_unreachable
    li $v0, 4
    syscall
grades_reachable:
    la $a0, str_nl
    li $v0, 4
    syscall

    # Progress bars: 20 characters, one per 5% of the degree
    la $a0, str_progress_now
    li $v0, 4
    syscall
    lw $t0, completed_credits
    j grades_draw_bar
grades_after_bar:
    la $a0, str_progress_after
    li $v0, 4
    syscall
    lw $t0, completed_credits
    lw $t1, semester_credits
    add $t0, $t0, $t1
    li $s7, 1                       # second bar marker
grades_draw_bar:
    lw $t2, degree_total_credits
    li $t3, 100
    mult $t0, $t3
    mflo $t3
    div $t3, $t2
    mflo $t8                        # percent complete
    li $t3, 5
    div $t8, $t3
    mflo $t9                        # filled characters
    li $t4, 0
grades_bar_loop:
    beq $t4, 20, grades_bar_done
    la $a0, bar_full
    blt $t4, $t9, grades_bar_char
    la $a0, bar_empty
grades_bar_char:
    li $v0, 4
    syscall
    addi $t4, $t4, 1
    j grades_bar_loop
grades_bar_done:
    la $a0, str_bar_close
    li $v0, 4
    syscall
    move $a0, $t8
    li $v0, 1
    syscall
    la $a0, str_percent
    li $v0, 4
    syscall
    beq $s7, 1, grades_done
    j grades_after_bar
grades_done:
    li $s7, 0
    jr $ra

# 3. Attendance planner (80% cutoff, 10 more classes assumed per subject)
#    classes needed = ceil(0.80 * (held + remaining)) - attended
print_attendance:
    la $a0, att_header
    li $v0, 4
    syscall
    li $t6, 0                       # subject index
    li $t7, 5                       # number of subjects
att_loop:
    beq $t6, $t7, att_done
    sll $t2, $t6, 2
    la $t1, subj_ptrs
    add $t1, $t1, $t2
    lw $a0, 0($t1)
    li $v0, 4
    syscall
    la $t3, classes_held
    add $t3, $t3, $t2
    lw $s1, 0($t3)                  # held
    la $t3, classes_att
    add $t3, $t3, $t2
    lw $s2, 0($t3)                  # attended
    lw $t4, remaining_classes_assumed

    li $t9, 100
    mult $s2, $t9
    mflo $t3
    div $t3, $s1
    mflo $t1                        # current percent

    move $a0, $s2
    li $v0, 1
    syscall
    la $a0, str_slash
    li $v0, 4
    syscall
    move $a0, $s1
    li $v0, 1
    syscall
    la $a0, str_space_paren
    li $v0, 4
    syscall
    move $a0, $t1
    li $v0, 1
    syscall
    la $a0, str_percent_closeparen
    li $v0, 4
    syscall

    lw $t0, cutoff_percent_int
    bge $t1, $t0, att_fulfilled
    add $t2, $s1, $t4               # total possible classes
    mult $t0, $t2
    mflo $t3
    addi $t3, $t3, 99               # ceiling division by 100
    li $t8, 100
    div $t3, $t8
    mflo $t5                        # classes that must be attended in total
    sub $t9, $t5, $s2               # still needed
    bgt $t9, $t4, att_not_possible
    la $a0, att_needs
    li $v0, 4
    syscall
    move $a0, $t9
    li $v0, 1
    syscall
    la $a0, att_of_next
    li $v0, 4
    syscall
    move $a0, $t4
    li $v0, 1
    syscall
    la $a0, str_nl
    li $v0, 4
    syscall
    j att_continue
att_fulfilled:
    la $a0, att_crit_fulfilled
    li $v0, 4
    syscall
    j att_continue
att_not_possible:
    la $a0, att_crit_not_fulfilled
    li $v0, 4
    syscall
att_continue:
    addi $t6, $t6, 1
    j att_loop
att_done:
    jr $ra

# 4. Personalised suggestions
print_suggestions:
    la $a0, suggest_header
    li $v0, 4
    syscall
    lw $t0, day_index
    la $t1, free_slots_ptrs
    sll $t2, $t0, 2
    add $t1, $t1, $t2
    lw $a0, 0($t1)
    li $v0, 4
    syscall

    lw $t0, student_id
    srl $t1, $t0, 2
    li $t2, 4
    div $t1, $t2
    mfhi $t3                        # personality = (ID >> 2) mod 4
    li $t4, 0
    move $t5, $t0
sum_digits_loop:
    beqz $t5, sum_digits_done
    li $t6, 10
    div $t5, $t6
    mfhi $t7
    add $t4, $t4, $t7
    mflo $t5
    j sum_digits_loop
sum_digits_done:
    li $t6, 5
    div $t4, $t6
    mfhi $t7                        # study pattern = digit sum mod 5

    beqz $t3, pers_lib
    li $t5, 1
    beq $t3, $t5, pers_canteen
    li $t5, 2
    beq $t3, $t5, pers_sports
    la $a0, pers_proj_str
    j pers_print
pers_lib:
    la $a0, pers_lib_str
    j pers_print
pers_canteen:
    la $a0, pers_canteen_str
    j pers_print
pers_sports:
    la $a0, pers_sports_str
pers_print:
    li $v0, 4
    syscall

    beqz $t7, sp_morning
    li $t8, 1
    beq $t7, $t8, sp_afternoon
    li $t8, 2
    beq $t7, $t8, sp_evening
    li $t8, 3
    beq $t7, $t8, sp_night
    la $a0, sp_default_str
    j sp_print
sp_morning:
    la $a0, sp_morning_str
    j sp_print
sp_afternoon:
    la $a0, sp_afternoon_str
    j sp_print
sp_evening:
    la $a0, sp_evening_str
    j sp_print
sp_night:
    la $a0, sp_night_str
sp_print:
    li $v0, 4
    syscall
    jr $ra
