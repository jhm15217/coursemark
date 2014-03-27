# ALL PASSWORDS ARE "agoraagora"
# Instructor login: admin@test.com (This is the user Aldorayne Grotkey) 
# Student login: student@test.com (This is the user Theodore Detweiller)

# All other passwords are [user first name]@test.com

# There are 8 users in the system
# There are 2 courses 2014, and 2015

# Aldorayne Grotkey is an instructor for both 2014 and 2015
# Muriel Finster is an instructor for only 2014
# Gretchen Priscilla is a student in 2014 and an instructor in 2015
# Theodore Detweiller and Ashley Spinelli are both students in both 2014 and 2015
# All other users are students registered for 2014 only

# 2014 Has four assignments
# Assignment 1 has been submitted, evaluated, and responded to by students and instructors
# Assignment 2 has been submitted
# Assignment 3 has not been submitted
# Assignment 4 is a draft

# 2015 Has one assignment, it is a draft

# IF YOU RUN rake db:seed:dump AGAIN IT WILL OVERWRITE THIS AND BREAK IT

User.create!([
  {first_name: "Aldorayne", last_name: "Grotkey", email: "admin@test.com", password: "agoraagora", password_confirmation: "agoraagora"},
  {first_name: "Muriel", last_name: "Finster", email: "Muriel@test.com", password: "agoraagora", password_confirmation: "agoraagora"},
  {first_name: "Theodore", last_name: "Detweiller", email: "student@test.com", password: "agoraagora", password_confirmation: "agoraagora"},
  {first_name: "Vincent", last_name: "LaSalle", email: "Vincent@test.com", password: "agoraagora", password_confirmation: "agoraagora"},
  {first_name: "Ashley", last_name: "Spinelli", email: "Ashley@test.com", password: "agoraagora", password_confirmation: "agoraagora"},
  {first_name: "Gretchen", last_name: "Priscilla", email: "Gretchen@test.com", password: "agoraagora", password_confirmation: "agoraagora"},
  {first_name: "Michael", last_name: "Blumberg", email: "Michael@test.com", password: "agoraagora", password_confirmation: "agoraagora"},
  {first_name: "Gustav", last_name: "Patton", email: "Gustav@test.com", password: "agoraagora", password_confirmation: "agoraagora"}
], :without_protection => true)

Course.create!([
  {name: "User-Centered Research and Evaluation - Spring 2014"},
  {name: "UCRE Fall 2015"}
])

Registration.create!([
  {instructor: true, active: true, user_id: 1, course_id: 1},
  {instructor: true, active: true, user_id: 1, course_id: 2},
  {instructor: true, active: true, user_id: 2, course_id: 1},
  {instructor: false, active: true, user_id: 3, course_id: 1},
  {instructor: false, active: true, user_id: 3, course_id: 2},
  {instructor: false, active: true, user_id: 4, course_id: 1},
  {instructor: false, active: true, user_id: 5, course_id: 1},
  {instructor: false, active: true, user_id: 5, course_id: 2},
  {instructor: false, active: true, user_id: 6, course_id: 1},
  {instructor: true, active: true, user_id: 6, course_id: 2},
  {instructor: false, active: true, user_id: 7, course_id: 1},
  {instructor: false, active: true, user_id: 8, course_id: 1}
])

Assignment.create!([
  {submission_due: "2013-03-27 23:46:10", review_due: "2012-03-27 23:46:10", reviews_required: 5, draft: false, course_id: 1, name: "Assignment 1 (Completed)"},
  {submission_due: "2013-03-27 23:46:10", review_due: "2015-03-27 23:46:10", reviews_required: 3, draft: false, course_id: 1, name: "Assignment 2 (Reviewing)"},
  {submission_due: "2015-03-27 23:46:10", review_due: "2016-03-27 23:46:10", reviews_required: 5, draft: false, course_id: 1, name: "Assignment 3 (Submitting)"},
  {submission_due: "2015-03-27 23:46:10", review_due: "2016-03-27 23:46:10", reviews_required: 5, draft: true, course_id: 1, name: "Assignment 4 (Draft)"},
  {submission_due: "2015-03-27 23:46:10", review_due: "2016-03-27 23:46:10", reviews_required: 0, draft: true, course_id: 2, name: "Assignment for 2015 (draft)"}
])


# Now generating evaluations when submissions are created
# Evaluation.create!([
#   {submission_id: 1, user_id: 4},
#   {submission_id: 1, user_id: 8},
#   {submission_id: 1, user_id: 7},
#   {submission_id: 1, user_id: 5},
#   {submission_id: 1, user_id: 6},
#   {submission_id: 2, user_id: 8},
#   {submission_id: 2, user_id: 6},
#   {submission_id: 2, user_id: 4},
#   {submission_id: 3, user_id: 3},
#   {submission_id: 3, user_id: 7},
#   {submission_id: 3, user_id: 6},
#   {submission_id: 3, user_id: 5},
#   {submission_id: 3, user_id: 8},
#   {submission_id: 4, user_id: 7},
#   {submission_id: 4, user_id: 3},
#   {submission_id: 4, user_id: 5},
#   {submission_id: 5, user_id: 4},
#   {submission_id: 5, user_id: 3},
#   {submission_id: 5, user_id: 6},
#   {submission_id: 5, user_id: 8},
#   {submission_id: 5, user_id: 7},
#   {submission_id: 6, user_id: 7},
#   {submission_id: 6, user_id: 3},
#   {submission_id: 6, user_id: 8},
#   {submission_id: 7, user_id: 4},
#   {submission_id: 7, user_id: 3},
#   {submission_id: 7, user_id: 5},
#   {submission_id: 7, user_id: 8},
#   {submission_id: 7, user_id: 7},
#   {submission_id: 8, user_id: 4},
#   {submission_id: 8, user_id: 5},
#   {submission_id: 8, user_id: 7},
#   {submission_id: 9, user_id: 5},
#   {submission_id: 9, user_id: 6},
#   {submission_id: 9, user_id: 3},
#   {submission_id: 9, user_id: 4},
#   {submission_id: 9, user_id: 8},
#   {submission_id: 10, user_id: 6},
#   {submission_id: 10, user_id: 4},
#   {submission_id: 10, user_id: 8},
#   {submission_id: 11, user_id: 6},
#   {submission_id: 11, user_id: 5},
#   {submission_id: 11, user_id: 7},
#   {submission_id: 11, user_id: 3},
#   {submission_id: 11, user_id: 4},
#   {submission_id: 12, user_id: 6},
#   {submission_id: 12, user_id: 5},
#   {submission_id: 12, user_id: 3}
# ])
Question.create!([
  {question_text: "Did the report have a title?", question_weight: 10, written_response_required: false, assignment_id: 1},
  {question_text: "Was the report good?", question_weight: 100, written_response_required: true, assignment_id: 1},
  {question_text: "Did the report have a title?", question_weight: 10, written_response_required: false, assignment_id: 2},
  {question_text: "Was the report good?", question_weight: 100, written_response_required: true, assignment_id: 2},
  {question_text: "Did the report have a title?", question_weight: 10, written_response_required: false, assignment_id: 3},
  {question_text: "Was the report good?", question_weight: 100, written_response_required: true, assignment_id: 3},
  {question_text: "Did the report have a title?", question_weight: 10, written_response_required: false, assignment_id: 4},
  {question_text: "Was the report good?", question_weight: 100, written_response_required: true, assignment_id: 4}
])

Scale.create!([
  {value: 1, description: "Yes, title included", question_id: 1},
  {value: 0, description: "NO! Not even a title!", question_id: 1},
  {value: 4, description: "IT WAS THE BEST THING I EVER READ", question_id: 2},
  {value: 3, description: "It was really good", question_id: 2},
  {value: 2, description: "It was really average?", question_id: 2},
  {value: 1, description: "No.", question_id: 2},
  {value: 0, description: "It was so bad I want to kill myself now", question_id: 2},
  {value: 1, description: "Yes, title included", question_id: 3},
  {value: 0, description: "NO! Not even a title!", question_id: 3},
  {value: 4, description: "IT WAS THE BEST THING I EVER READ", question_id: 4},
  {value: 3, description: "It was really good", question_id: 4},
  {value: 2, description: "It was really average?", question_id: 4},
  {value: 1, description: "No.", question_id: 4},
  {value: 0, description: "It was so bad I want to kill myself now", question_id: 4},
  {value: 1, description: "Yes, title included", question_id: 5},
  {value: 0, description: "NO! Not even a title!", question_id: 5},
  {value: 4, description: "IT WAS THE BEST THING I EVER READ", question_id: 6},
  {value: 3, description: "It was really good", question_id: 6},
  {value: 2, description: "It was really average?", question_id: 6},
  {value: 1, description: "No.", question_id: 6},
  {value: 0, description: "It was so bad I want to kill myself now", question_id: 6},
  {value: 1, description: "Yes, title included", question_id: 7},
  {value: 0, description: "NO! Not even a title!", question_id: 7},
  {value: 4, description: "IT WAS THE BEST THING I EVER READ", question_id: 8},
  {value: 3, description: "It was really good", question_id: 8},
  {value: 2, description: "It was really average?", question_id: 8},
  {value: 1, description: "No.", question_id: 8},
  {value: 0, description: "It was so bad I want to kill myself now", question_id: 8}
])


# Need to come last
Submission.create!([
  {submitted: nil, submission: nil, assignment_id: 1, user_id: 3, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 2, user_id: 3, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 1, user_id: 4, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 2, user_id: 4, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 1, user_id: 5, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 2, user_id: 5, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 1, user_id: 6, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 2, user_id: 6, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 1, user_id: 7, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 2, user_id: 7, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 1, user_id: 8, instructor_approved: nil},
  {submitted: nil, submission: nil, assignment_id: 2, user_id: 8, instructor_approved: nil}
])
