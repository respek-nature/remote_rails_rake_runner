RemoteRailsRakeRunner::Engine.routes.draw do
  root 'runner#index'
  post '/:task', to: 'runner#run', as: :rake
  post '/reenable/all', to: 'runner#reneable_environment', as: :reenable_all
  post '/reenable/:task', to: 'runner#reneable_rake', as: :reenable_rake
end
