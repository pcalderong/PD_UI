json.array!(@hohos) do |hoho|
  json.extract! hoho, :id, :my
  json.url hoho_url(hoho, format: :json)
end
