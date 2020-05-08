
# Welcome, let's get going

First, let's know what your domain is:

<%= form_tag admin_relying_parties_path, method: :get, class: 'w-full' do %>
<%= label_tag :id, 'Domain:', class: 'input-label' %>
<%= text_field_tag(:id, nil, class: 'login-input', placeholder: 'example.com') %>
<%= submit_tag 'Go', class: 'button primary mt-4' %>
<% end %>
