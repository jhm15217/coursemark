# encoding: UTF-8
# This file is auto-generated from the current state of the database. Instead
# of editing this file, please use the migrations feature of Active Record to
# incrementally modify your database, and then regenerate this schema definition.
#
# Note that this schema.rb definition is the authoritative source for your
# database schema. If you need to create the application database on another
# system, you should be using db:schema:load, not running all the migrations
# from scratch. The latter is a flawed and unsustainable approach (the more migrations
# you'll amass, the slower it'll run and the greater likelihood for issues).
#
# It's strongly recommended to check this file into your version control system.

ActiveRecord::Schema.define(:version => 20140930031627) do

  create_table "assignments", :force => true do |t|
    t.datetime "submission_due"
    t.datetime "review_due"
    t.integer  "reviews_required"
    t.boolean  "draft"
    t.integer  "course_id"
    t.datetime "created_at",                                              :null => false
    t.datetime "updated_at",                                              :null => false
    t.string   "name"
    t.boolean  "manual_assignment"
    t.boolean  "reviewers_assigned"
    t.boolean  "team"
    t.integer  "instructor_reviews_required",              :default => 0
    t.text     "cached_sort"
    t.integer  "sort_hash",                   :limit => 8
  end

  create_table "courses", :force => true do |t|
    t.string   "name"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "course_code"
  end

  create_table "evaluations", :force => true do |t|
    t.integer  "submission_id"
    t.integer  "user_id"
    t.datetime "created_at",    :null => false
    t.datetime "updated_at",    :null => false
    t.boolean  "finished"
  end

  create_table "memberships", :force => true do |t|
    t.string   "team"
    t.integer  "user_id"
    t.integer  "assignment_id"
    t.datetime "created_at",     :null => false
    t.datetime "updated_at",     :null => false
    t.integer  "pseudo_user_id"
  end

  create_table "questions", :force => true do |t|
    t.text     "question_text"
    t.integer  "question_weight"
    t.boolean  "written_response_required"
    t.integer  "assignment_id"
    t.datetime "created_at",                :null => false
    t.datetime "updated_at",                :null => false
  end

  create_table "registrations", :force => true do |t|
    t.boolean  "instructor"
    t.boolean  "active"
    t.integer  "user_id"
    t.integer  "course_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
    t.string   "course_code"
    t.string   "section"
  end

  create_table "responses", :force => true do |t|
    t.text     "peer_review"
    t.text     "student_response"
    t.text     "instructor_response"
    t.integer  "evaluation_id"
    t.integer  "question_id"
    t.integer  "scale_id"
    t.datetime "created_at",          :null => false
    t.datetime "updated_at",          :null => false
  end

  create_table "scales", :force => true do |t|
    t.integer  "value"
    t.text     "description"
    t.integer  "question_id"
    t.datetime "created_at",  :null => false
    t.datetime "updated_at",  :null => false
  end

  create_table "submissions", :force => true do |t|
    t.integer  "assignment_id"
    t.integer  "user_id"
    t.datetime "created_at",              :null => false
    t.datetime "updated_at",              :null => false
    t.boolean  "instructor_approved"
    t.string   "attachment_file_name"
    t.string   "attachment_content_type"
    t.integer  "attachment_file_size"
    t.datetime "attachment_updated_at"
    t.string   "url"
  end

  create_table "team_memberships", :force => true do |t|
    t.integer  "team_id"
    t.integer  "user_id"
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "teams", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "user_sessions", :force => true do |t|
    t.datetime "created_at", :null => false
    t.datetime "updated_at", :null => false
  end

  create_table "users", :force => true do |t|
    t.string   "first_name"
    t.string   "last_name"
    t.string   "email"
    t.datetime "created_at",             :null => false
    t.datetime "updated_at",             :null => false
    t.string   "crypted_password"
    t.string   "password_salt"
    t.string   "persistence_token"
    t.boolean  "confirmed"
    t.string   "confirmation_token"
    t.datetime "password_reset_sent_at"
    t.boolean  "pseudo"
  end

end
