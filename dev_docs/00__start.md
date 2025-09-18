# 17 set 2021

rails g controller dashboard user
rails g controller courses index show

rails g scaffold TrainingCourse \
  course_slug:string:index \
  registrations_open_at:datetime \
  registrations_close_at:datetime \
  package_slug:string:index \
  tutor_role_id:integer \
  teacher_role_id:integer \
  trainee_role_id:integer \
  venue_manager_role_id:integer \
  location_name:text \
  location_address:text \
  location_gmaps:string \
  lat:float \
  lng:float \
  location_phone:string \
  participants_count:integer \

rails g controller Pages home index about contact
rails g authentication 


# 12 set 2021
rails new flowpulseaccademy --database=postgresql --css=tailwind


Sviluppo piattaforma corsi online per Flowpulse Accademy
