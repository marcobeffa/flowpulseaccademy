<% if service_mounted?(:onlinecourses) %>
  <%= link_to "Catalogo", onlinecourses_catalog_path %>
<% elsif service_enabled_for_current_domain?(:onlinecourses) %>
  <%= link_to "Catalogo", service_url_for(:onlinecourses) %>
<% end %>

<% if service_enabled_for_current_domain?(:onlinecourses) %>
  <%= link_to "Corsi online", onlinecourses_catalog_path %>
<% end %>

<% if (url = service_url_for(:onlinecourses)) %>
  <%= link_to "Catalogo corsi", url %>
<% end %>
Link al root del sottodominio flowpulse.<dominio>:

erb
Copia codice
<% if (url = service_root_url(:onlinecourses)) %>
  <%= link_to "Flowpulse", url %>
<% end %>

3) Se intendevi “se il sottodominio flowpulse esiste, linka lì”

Puoi usare direttamente l’host calcolato:

<% if (host = service_host_for(:onlinecourses)) %>
  <% port = request.port && ![80, 443].include?(request.port) ? ":#{request.port}" : "" %>
  <%= link_to "Vai su Flowpulse",
              "#{request.protocol}#{host}#{port}/onlinecourses" %>
<% end %>