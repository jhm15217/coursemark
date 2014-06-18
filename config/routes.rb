Agora::Application.routes.draw do
  resources :groups


  get 'submission_submission/:id', :to => 'submissions#view'
  get 'register', :to => 'users#new'
  match 'registrations/add_to_course_staff' => 'registrations#add_to_course_staff'
  match 'assignments/publish' => 'assignments#publish'

  get "users/new"
  get "users/edit"
  get "user_sessions/new"

  resources :courses do
    resources :assignments do
      get 'export', :controller => 'assignments', :action => 'export'

      resources :submissions do
        resources :evaluations
      end

      resources :questions do
        resources :responses
        resources :scales
      end

      resources :reviews do
        get :assign_reviews, :on => :collection
        post :edit_review, :on => :collection
      end
      
    end
  end

  resources :password_resets, only: [:new, :create, :update]

  resources :registrations

  resources :users do
    resources :emails, only: [:index, :show, :destroy]
    member do
      get :received
      post :resend_confirm_email
    end
  end

  get 'login', :controller => 'user_sessions', :action => 'new'  
  get 'logout', :controller => 'user_sessions', :action => 'destroy'  
  resources :user_sessions 

  root :to => 'courses#index'

  match 'users/:id/reset_password/:confirmation_token',
        to: 'password_resets#edit',
        as: :reset_password
  match '/signin',  to: 'user_sessions#new'
  match '/email_confirmation', to: 'static_pages#email_confirmation_sent'
  match 'users/:id/confirm/:confirmation_token',
        to: 'users#confirm_email',
        as: :confirm_email


# The priority is based upon order of creation:
  # first created -> highest priority.

  # Sample of regular route:
  #   match 'products/:id' => 'catalog#view'
  # Keep in mind you can assign values other than :controller and :action

  # Sample of named route:
  #   match 'products/:id/purchase' => 'catalog#purchase', :as => :purchase
  # This route can be invoked with purchase_url(:id => product.id)

  # Sample resource route (maps HTTP verbs to controller actions automatically):
  #   resources :products

  # Sample resource route with options:
  #   resources :products do
  #     member do
  #       get 'short'
  #       post 'toggle'
  #     end
  #
  #     collection do
  #       get 'sold'
  #     end
  #   end

  # Sample resource route with sub-resources:
  #   resources :products do
  #     resources :comments, :sales
  #     resource :seller
  #   end

  # Sample resource route with more complex sub-resources
  #   resources :products do
  #     resources :comments
  #     resources :sales do
  #       get 'recent', :on => :collection
  #     end
  #   end

  # Sample resource route within a namespace:
  #   namespace :admin do
  #     # Directs /admin/products/* to Admin::ProductsController
  #     # (app/controllers/admin/products_controller.rb)
  #     resources :products
  #   end

  # You can have the root of your site routed with "root"
  # just remember to delete public/index.html.
  # root :to => 'welcome#index'

  # See how all your routes lay out with "rake routes"

  # This is a legacy wild controller route that's not recommended for RESTful applications.
  # Note: This route will make all actions in every controller accessible via GET requests.
  # match ':controller(/:action(/:id))(.:format)'
end
