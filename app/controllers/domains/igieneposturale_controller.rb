# app/controllers/domains/posturacorretta_controller.rb
module Domains
 class IgieneposturaleController < BrandBaseController
  allow_unauthenticated_access

  layout "igieneposturale"
  self.default_brand_slug = "igieneposturale"
   # def about; super; end  # (solo se vuoi personalizzare)
 end
end
