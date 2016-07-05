# This is a manifest file that will be compiled into application.js, which will include all the files
# listed below.
#
# Any JavaScript/Coffee file within this directory, lib/assets/javascripts, vendor/assets/javascripts,
# or vendor/assets/javascripts of plugins, if any, can be referenced here using a relative path.
#
# It's not advisable to add code directly here, but if you do, it'll appear at the bottom of the
# compiled file.
#
# WARNING: THE FIRST BLANK LINE MARKS THE END OF WHAT'S TO BE PROCESSED, ANY BLANK LINE SHOULD
# GO AFTER THE REQUIRES BELOW.
#
#= require jquery
#= require jquery_ujs
#= require turbolinks
#= require bootstrap
#= require hierapolis
#= require jquery.purr
#= require dataTables/jquery.dataTables
#= require bootstrap-datepicker
#= require bootstrap-datepicker/core
#= require bootstrap-datepicker/locales/bootstrap-datepicker.es.js
#= require best_in_place

ready = ->
  # TODO

$(document).ready(ready)
$(document).on('page:load', ready)
$(window).on('page:load', ready)
jQuery(document).ready ($) ->
  $('.best_in_place').best_in_place()
  return

jQuery(document).ready ($) ->
  $('#lookups_table').dataTable
    "scrollY": "200px"
    "scrollCollapse": true
    "paging": true
    'language':
      'lengthMenu': 'Mostrando _MENU_ registros por pagina'
      'zeroRecords': 'No existen registros'
      'info': 'Mostrando pagina _PAGE_ de _PAGES_'
      'infoEmpty': 'No hay registros disponibles'
  return
