FactoryGirl.define do
  factory :user do
    sequence(:first_name)  { |n| "Person #{n}" }
    last_name 'Student'
    sequence(:email) { |n| "person_#{n}@example.com" }
    password "foobar1."
    password_confirmation "foobar1."
    confirmed true   # reset to false for account creation and comfirmation tests


    factory :admin do
      admin true
    end
  end

  factory :email do
    body = %Q{Lorem ipsum dolor sit amet, consectetur adipiscing elit. Aliquam
      sed ligula a orci gravida ornare. In laoreet orci sit amet lorem eleifend
      pharetra. Nunc interdum eros in magna condimentum dignissim. Suspendisse
      sit amet metus neque.
      <more>}
    sequence(:to)  { |n| "someone_#{n}@email.com"}
    sequence(:from)  { |n| "someone_#{n+1}@email.com"}
    subject "Nothing"
    body body
  end

end
