Assignment.create!([
  {submission_due: "2014-02-28 04:29:00", review_due: "2014-03-01 04:29:00", reviews_required: 4, draft: false, course_id: 1, name: "Assignment 1"}
])
Course.create!([
  {name: "UCRE"}
])
Evaluation.create!([
  {submission_id: 1, user_id: 2}
])
Question.create!([
  {question_text: "How much wood could a wood chuck chuck if a wood chuck could chuck wood?", question_weight: 1, written_response_required: true, assignment_id: 1}
])
Submission.create!([
  {submitted: "2014-02-27 04:50:00", submission: "", assignment_id: 1, user_id: 1}
])
User.create!([
  {first_name: "Kevin", last_name: "Schaefer", email: "kjschaef@andrew.cmu.edu", password: "nyan", password_digest: "nyan"},
  {first_name: "Hayden", last_name: "Demerson", email: "ddemerso@andrew.cmu.edu", password: "nyan", password_digest: "nyan"},
  {first_name: "Alex", last_name: "Stern", email: "aestern@andrew.cmu.edu", password: "nyan", password_digest: "nyan"}
])
