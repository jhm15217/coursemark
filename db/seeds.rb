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

people = [
  {first_name: 'Aldorayne', last_name: 'Grotkey', email: 'admin@test.com'}, 
  {first_name: 'Muriel', last_name: 'Finster'},
  {first_name: 'Theodore', last_name: 'Detweiller', email: 'student@test.com'},
  {first_name: 'Vincent', last_name: 'LaSalle'},
  {first_name: 'Ashley', last_name: 'Spinelli'},
  {first_name: 'Gretchen', last_name: 'Priscilla'},
  {first_name: 'Michael', last_name: 'Blumberg'},
  {first_name: 'Gustav', last_name: 'Patton'}
]

lorem = "Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque congue " +
"luctus erat, sit amet pharetra ligula sollicitudin non. In tellus nisi, viverra " + 
"vitae metus sit amet, sodales accumsan mi. Nam fringilla leo vel est feugiat, vitae " + 
"ornare mauris gravida. In quis eros vitae eros hendrerit dignissim." +
"Lorem ipsum dolor sit amet, consectetur adipiscing elit. Quisque congue " +
"luctus erat, sit amet pharetra ligula sollicitudin non. In tellus nisi, viverra " + 
"vitae metus sit amet, sodales accumsan mi. Nam fringilla leo vel est feugiat, vitae " + 
"ornare mauris gravida. In quis eros vitae eros hendrerit dignissim."

users = Hash.new

for person in people
  user = User.new
  user.first_name = person[:first_name]
  user.last_name = person[:last_name]
  user.email = person[:email] || person[:first_name] + "@test.com"
  user.password = person[:password] || 'agoraagora'
  user.password_confirmation = person[:password] || 'agoraagora'
  user.save
  users[person[:first_name]] = user
end

courseUCRE2014 = Course.create(name: 'User-Centered Research and Evaluation - Spring 2014')
courseUCRE2015 = Course.create(name: 'UCRE Fall 2015')

# Aldorayne is an instructor for both 2014, 2015
# Muriel is an instructor only for 2014
# Gretchen is a student in 2014 and an instructor in 2015
# Ashley and Theodore are registered for 2014 and 2015 as students
# All other people are students for 2014 only

enrollments = [
  {course: courseUCRE2014, user: users["Aldorayne"], instructor: true},
  {course: courseUCRE2015, user: users["Aldorayne"], instructor: true},
  {course: courseUCRE2014, user: users["Muriel"], instructor: true},
  {course: courseUCRE2014, user: users["Theodore"]},
  {course: courseUCRE2015, user: users["Theodore"]},
  {course: courseUCRE2014, user: users["Vincent"]},
  {course: courseUCRE2014, user: users["Ashley"]},
  {course: courseUCRE2015, user: users["Ashley"]},
  {course: courseUCRE2014, user: users["Gretchen"]},
  {course: courseUCRE2015, user: users["Gretchen"], instructor: true},
  {course: courseUCRE2014, user: users["Michael"]},
  {course: courseUCRE2014, user: users["Gustav"]},
]

for enrollment in enrollments
  Registration.create({
    active: enrollment[:active] || true,
    course_id: enrollment[:course].id,
    user_id: enrollment[:user].id,
    instructor: enrollment[:instructor] || false
  })
end

assignment1 = Assignment.new(
  course_id: courseUCRE2014.id, 
  draft: false,
  review_due: 2.years.ago.beginning_of_hour,
  reviews_required: 5,
  submission_due: 1.year.ago.beginning_of_hour,
  name: "Assignment 1 (Completed)"
)
assignment1.save(:validate => false)

assignment2 = Assignment.new(
  course_id: courseUCRE2014.id, 
  draft: false,
  review_due: 1.year.from_now.beginning_of_hour,
  reviews_required: 3,
  submission_due: 1.year.ago.beginning_of_hour,
  name: "Assignment 2 (Reviewing)"
)
assignment2.save(:validate => false)

assignment3 = Assignment.new(
  course_id: courseUCRE2014.id, 
  draft: false,
  review_due: 2.year.from_now.beginning_of_hour,
  reviews_required: 5,
  submission_due: 1.year.from_now.beginning_of_hour,
  name: "Assignment 3 (Submitting)"
)
assignment3.save(:validate => false)

assignment4 = Assignment.new(
  course_id: courseUCRE2014.id, 
  draft: true,
  review_due: 2.year.from_now.beginning_of_hour,
  reviews_required: 5,
  submission_due: 1.year.from_now.beginning_of_hour,
  name: "Assignment 4 (Draft)"
)
assignment4.save(:validate => false)

assignment5 = Assignment.new(
  course_id: courseUCRE2015.id, 
  draft: true,
  review_due: 2.year.from_now.beginning_of_hour,
  reviews_required: 0,
  submission_due: 1.year.from_now.beginning_of_hour,
  name: "Assignment for 2015 (draft)"
)
assignment5.save(:validate => false)

assignments = [assignment1, assignment2, assignment3, assignment4]

for assignment in assignments 
  question1 = Question.create({assignment_id: assignment.id,
                 question_text: 'Did the report have a title?',
                 question_weight: 10,
                 written_response_required: false})
  Scale.create({description: "Yes, title included", question_id: question1.id, value: 1})
  Scale.create({description: "NO! Not even a title!", question_id: question1.id, value: 0})

  question2 = Question.create({assignment_id: assignment.id,
                 question_text: 'Was the report good?',
                 question_weight: 100,
                 written_response_required: true})
  Scale.create({description: "IT WAS THE BEST THING I EVER READ", question_id: question2.id, value: 4})
  Scale.create({description: "It was really good", question_id: question2.id, value: 3})
  Scale.create({description: "It was really average?", question_id: question2.id, value: 2})
  Scale.create({description: "No.", question_id: question2.id, value: 1})
  Scale.create({description: "It was so bad I want to kill myself now", question_id: question2.id, value: 0})
end

evaluations = []

students2014 = people[2..people.length]
for student in students2014
  for assignment in [assignment1, assignment2]
    submission = Submission.new
    submission.assignment_id = assignment.id
    submission.user_id = users[student[:first_name]].id
    # not actually supplying a file to submit
    # submission.submission = params[:file]
    # submission.submission = File.open('')
    submission.save(:validate => false)
    # assignment.reviews_required.times do |i|
    #   evaluation = Evaluation.new
    #   evaluation.submission_id = submission.id
    #   evaluator = students2014[(students2014.index(student) + i + 1) % students2014.length]
    #   evaluation.user_id = users[evaluator[:first_name]].id
    #   evaluation.save
    #   evaluations.push(evaluation)      
    # end
  end
end

evaluations = Evaluation.all
for evaluation in evaluations
  if evaluation.submission.assignment_id == assignment1.id
    for question in evaluation.submission.assignment.questions
      response = Response.new
      response.question_id = question.id
      response.evaluation_id = evaluation.id
      response.scale_id = question.scales.sample.id
      if question.written_response_required
        response.peer_review = lorem[0..rand(lorem.length)]
      else
        if rand(2) == 1
          response.peer_review = lorem[0..rand(lorem.length)]
        end
      end
      if rand(3) == 1
        response.student_response = lorem[0..rand(lorem.length)]
      end
      if rand(3) == 1
        response.student_response = lorem[0..rand(lorem.length)]
      end
      response.save(:validate => false)
    end
  end
end
