
require 'spreadsheet'
require 'spreadsheet/excel'

class ReportsController < ApplicationController


  def index
    @reports = Report.all
    @hospitales = Lookup.where("lookup_type = ?", "Hospital")
    @provincias = Lookup.where("descripcion = ?", "Provincia")
    @cantones = Lookup.where("descripcion = ?", "Canton - #{@provincias.first.value}")
    @distritos = Lookup.where("descripcion = ?", "Distrito - #{@cantones.first.value}")
    @padecimientos = Lookup.where("descripcion = ?", "Padecimiento")
    @tipos_padecimientos = Lookup.where("descripcion = ?", "Padecimiento - #{@padecimientos.first.value}")
  end

  def generate_report
    case params[:report]
      when "Pacientes_Hospital"
        generate_report_by_hospital()
      when "Pacientes_Fallecidos_Periodo"
        generate_report_by_fallecidos()
      when "Pacientes_Genero"
        generate_report_by_genero()
      when "Pacientes_Nuevos_Mes"
        generate_report_by_mes()
      when "Pacientes_Ubicacion"
        generate_report_by_ubicacion()
      when "Pacientes_Padecimiento"
        generate_report_by_padecimiento()
      when "Pacientes_Centro_Estudio"
        generate_report_by_centro_estudio()
      when "Pacientes_Con_Hijos"
        generate_report_by_hijos()
      when "Pacientes_Por_Edad"
        generate_report_by_edad()
    end

  end

  def generate_report_by_hospital
    report_id = Report.find(1)
    @results_hash = Hash.new()
    @hospitales = Lookup.where(:lookup_type => 'Hospital')
    @hospitales.each do |h|
      pacientes_hospi = Persona.joins(:diagnosticos)
                                .where(:diagnosticos => {:hospital => h.id})
                                .group("personas.id")
                                .order(:primer_apellido)
      @results_hash[h.value] = pacientes_hospi
    end
    create_doc_reporte_categoria(@results_hash, "Hospitales")
  end

  def generate_report_by_fallecidos
    report_id = Report.find(2)
    if (params[:fecha_ini].eql?("") && params[:fecha_fin].eql?(""))
      @pacientes_fallecidos = Persona.joins(:historial_clinicos)
                                .where(:historial_clinicos => {:fk_id_lookup => '7'})
                                .group("personas.id")
    elsif
      fecha_ini = Date.parse(params[:fecha_ini])
      if params[:fecha_fin].eql?("")
        fecha_fin = Date.today
      else
        fecha_fin = Date.parse(params[:fecha_fin])
      end
      @pacientes_fallecidos = Persona.joins(:historial_clinicos)
                                .where(:historial_clinicos => {:fecha => (fecha_ini .. fecha_fin), :fk_id_lookup => '7'})
                                .group("personas.id")
    end
    create_doc_reporte(@pacientes_fallecidos,"fallecidos")
  end

  def generate_report_by_genero
    report_id = Report.find(3)
    @results_hash = {"Mujeres" => "", "Hombres" => "" }
    2.times do |i|
      pacientes_genero = Persona.where(:genero => gender(i))
                                .group("personas.id")
      if gender(i)
        @results_hash["Hombres"]=pacientes_genero
      else
        @results_hash["Mujeres"]=pacientes_genero
      end
    end
    create_doc_reporte_categoria(@results_hash,"Genero")
  end

  def generate_report_by_mes
    report_id = Report.find(3)
    @pacientes_mes = Persona.where(:created_at =>  (Date.today.at_beginning_of_month .. Date.today.at_end_of_month))
                              .group("personas.id")
    create_doc_reporte(@pacientes_mes, Date.today.strftime("%B"))
  end

  def generate_report_by_ubicacion
    report_id = Report.find(4)
    @results_hash = Hash.new()
    @provincias = Lookup.where(:lookup_type => 'Direccion', :descripcion => 'Provincia')
    @provincias.each do |prov|
      pacientes_ubicacion = Persona.joins(:direccions)
                                    .select("personas.*, direccions.*")
                                    .where(:direccions =>  {:provincia => prov.id})
                                .group("personas.id")
      @results_hash[prov.value] = pacientes_ubicacion
    end

    puts "Reporte Pacientes: #{@results_hash.inspect}"
    create_doc_reporte_ubicacion(@results_hash, "Ubicacion")
  end

  def generate_report_by_padecimiento
    report_id = Report.find(5)
    @results_hash = Hash.new()
    @padecimientos = Lookup.where(:lookup_type => 'Padecimiento', :descripcion => 'Padecimiento')
    @padecimientos.each do |pad|
      pacientes_padecimiento = Persona.joins(:diagnosticos)
                                    .select("personas.*, diagnosticos.*")
                                    .where(:diagnosticos =>  {:padecimiento => pad.id})
                                .group("personas.id")
      @results_hash[pad.value] = pacientes_padecimiento
    end

    puts "Reporte Pacientes: #{@results_hash.inspect}"
    create_doc_reporte_padecimiento(@results_hash, "Padecimientos")
    # redirect_to reports_url
  end

  def generate_report_by_centro_estudio
    report_id = Report.find(5)
    @pacientes_centro_estudio= Persona.joins(:info_extra_pacientes)
                                  .select("personas.*, info_extra_pacientes.*")
                                  .where("info_extra_pacientes.lugar_estudio_trabajo IS NOT NULL ")
                              .group("personas.id")
                              .order("info_extra_pacientes.lugar_estudio_trabajo")
    puts "Reporte Pacientes: #{@pacientes_centro_estudio.inspect}"
    create_doc_reporte_centro_estudio(@pacientes_centro_estudio, "Centro_Estudio")
    # redirect_to reports_url
  end

  def generate_report_by_hijos
    report_id = Report.find(5)
    @pacientes_hijos= Persona.joins(:info_extra_pacientes)
                              .where(:info_extra_pacientes => {:hijos => 1 })
    puts "Reporte Pacientes: #{@pacientes_hijos.inspect}"
    create_doc_reporte_hijos(@pacientes_hijos, "Hijos")
    # redirect_to reports_url
  end

  def generate_report_by_edad
    report_id = Report.find(6)
    date_ini = Date.new(Date.today.year - params[:edad_ini].to_i)
    date_fin = Date.new(Date.today.year - params[:edad_fin].to_i)
    if params[:edad_ini].to_i == 0 and params[:edad_fin].to_i == 0
      @pacientes_edad = Persona.all.order(fecha_nacimiento: :desc)
    else
      @pacientes_edad= Persona.where(:fecha_nacimiento => (date_fin .. date_ini))
    end
    create_doc_reporte_edad(@pacientes_edad, "Edad")
    # redirect_to reports_url
  end


  def create_doc_reporte_categoria(personas, reporte)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    personas.each do |k, list_p|
      sheet = book.create_worksheet
      sheet.name = k
      sheet.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono Edad}
      i=1
      list_p.each do |p|
        sheet.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido, p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono, p.fecha_nacimiento.nil? ? " ":get_age(p.fecha_nacimiento)
        i=i+1
      end
      sheet.row(0).height = 18

      format = Spreadsheet::Format.new :color => :orange,
                                       :weight => :bold,
                                       :size => 20
      sheet.row(0).default_format = format

      bold = Spreadsheet::Format.new :weight => :bold
      4.times do |x| sheet.row(x + 1).set_format(0, bold) end
    end
    t = Time.now.strftime('%v %r')
    book.write "Pacientes-#{reporte}-#{t}.xls"
    send_file "Pacientes-#{reporte}-#{t}.xls", :type=>"application/excel", :filename => "Pacientes-#{reporte}-#{t}.xls", :stream => false
  end

  def create_doc_reporte_ubicacion(personas, reporte)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    personas.each do |k, list_p|
      sheet = book.create_worksheet
      sheet.name = k
      sheet.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono Edad Canton Distrito DireccionExacta}
      i=1
      list_p.each do |p|
        sheet.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido,
                          p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono,
                          p.fecha_nacimiento.nil? ? " ":get_age(p.fecha_nacimiento),
                          p.canton.nil? ? " ":id_to_value_direccion(p.canton), p.distrito.nil? ? " ":id_to_value_direccion(p.distrito),
                          p.direccion_exacta.nil? ? " ":p.direccion_exacta
        i=i+1
      end
      sheet.row(0).height = 18

      format = Spreadsheet::Format.new :color => :orange,
                                       :weight => :bold,
                                       :size => 20
      sheet.row(0).default_format = format

      bold = Spreadsheet::Format.new :weight => :bold
      4.times do |x| sheet.row(x + 1).set_format(0, bold) end
    end
    t = Time.now.strftime('%v %r')
    book.write "Pacientes-#{reporte}-#{t}.xls"
    send_file "Pacientes-#{reporte}-#{t}.xls", :type=>"application/excel", :filename => "Pacientes-#{reporte}-#{t}.xls", :stream => false
  end

  def create_doc_reporte_padecimiento(personas, reporte)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    personas.each do |k, list_p|
      sheet = book.create_worksheet
      sheet.name = k
      sheet.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono Edad Especialidad Padecimiento Hospital FechaDiagnostico}
      i=1
      list_p.each do |p|
        sheet.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido,
                          p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono,
                          p.fecha_nacimiento.nil? ? " ":get_age(p.fecha_nacimiento),
                          p.especialidad_id.nil? ? " ":id_to_value_direccion(p.especialidad_id),
                          p.tipo_padecimiento.nil? ? " ":id_to_value_direccion(p.tipo_padecimiento),
                          p.hospital.nil? ? " ":id_to_value_direccion(p.hospital),
                          p.fecha.nil? ? " ":p.fecha.strftime('%d/%m/%Y')

        i=i+1
      end
      sheet.row(0).height = 18

      format = Spreadsheet::Format.new :color => :orange,
                                       :weight => :bold,
                                       :size => 20
      sheet.row(0).default_format = format

      bold = Spreadsheet::Format.new :weight => :bold
      4.times do |x| sheet.row(x + 1).set_format(0, bold) end
    end
    t = Time.now.strftime('%v %r')
    book.write "Pacientes-#{reporte}-#{t}.xls"
    send_file "Pacientes-#{reporte}-#{t}.xls", :type=>"application/excel", :filename => "Pacientes-#{reporte}-#{t}.xls", :stream => false
  end

  def create_doc_reporte_centro_estudio(personas, reporte)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet
    sheet1.name = 'Informacion Pacientes'
    sheet1.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono CentroEstudio}
    i=1
    personas.each do |p|
      sheet1.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido, p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono, p.lugar_estudio_trabajo
      i=i+1
    end
    sheet1.row(0).height = 18

    format = Spreadsheet::Format.new :color => :orange,
                                     :weight => :bold,
                                     :size => 18
    sheet1.row(0).default_format = format

    bold = Spreadsheet::Format.new :weight => :bold
    4.times do |x| sheet1.row(x + 1).set_format(0, bold) end
    # book.write '/Users/paolacalderon/Documents/ProyectoDaniel/excel-pacientes.xls'
    t = Time.now.strftime('%v %r')
    book.write "Pacientes-#{reporte}-#{t}.xls"
    send_file "Pacientes-#{reporte}-#{t}.xls", :type=>"application/excel", :filename => "Pacientes-#{reporte}-#{t}.xls", :stream => false
  end

  def create_doc_reporte(personas, reporte)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet
    sheet1.name = 'Informacion Pacientes'
    sheet1.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono}
    i=1
    personas.each do |p|
      sheet1.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido, p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono
      i=i+1
    end
    sheet1.row(0).height = 18

    format = Spreadsheet::Format.new :color => :orange,
                                     :weight => :bold,
                                     :size => 18
    sheet1.row(0).default_format = format

    bold = Spreadsheet::Format.new :weight => :bold
    4.times do |x| sheet1.row(x + 1).set_format(0, bold) end
    # book.write '/Users/paolacalderon/Documents/ProyectoDaniel/excel-pacientes.xls'
    t = Time.now.strftime('%v %r')
    book.write "Pacientes-#{reporte}-#{t}.xls"
    send_file "Pacientes-#{reporte}-#{t}.xls", :type=>"application/excel", :filename => "Pacientes-#{reporte}-#{t}.xls", :stream => false
  end

  def create_doc_reporte_hijos(personas, reporte)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet
    sheet1.name = 'Informacion Pacientes'
    sheet1.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono CantidadHijos}
    i=1
    personas.each do |p|
      sheet1.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido, p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono, p.info_extra_pacientes[0].cant_hijos
      i=i+1
    end
    sheet1.row(0).height = 18

    format = Spreadsheet::Format.new :color => :orange,
                                     :weight => :bold,
                                     :size => 18
    sheet1.row(0).default_format = format

    bold = Spreadsheet::Format.new :weight => :bold
    4.times do |x| sheet1.row(x + 1).set_format(0, bold) end
    # book.write '/Users/paolacalderon/Documents/ProyectoDaniel/excel-pacientes.xls'
    t = Time.now.strftime('%v %r')
    book.write "Pacientes-#{reporte}-#{t}.xls"
    send_file "Pacientes-#{reporte}-#{t}.xls", :type=>"application/excel", :filename => "Pacientes-#{reporte}-#{t}.xls", :stream => false
  end

  def create_doc_reporte_edad(personas, reporte)
    Spreadsheet.client_encoding = 'UTF-8'
    book = Spreadsheet::Workbook.new
    sheet1 = book.create_worksheet
    sheet1.name = 'Informacion Pacientes'
    sheet1.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono Edad FechaNacimiento}
    i=1
    personas.each do |p|
      sheet1.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido,
                          p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono,
                          p.fecha_nacimiento.nil? ? " ":get_age(p.fecha_nacimiento),
                          p.fecha_nacimiento
      i=i+1
    end
    sheet1.row(0).height = 18

    format = Spreadsheet::Format.new :color => :orange,
                                     :weight => :bold,
                                     :size => 18
    sheet1.row(0).default_format = format

    bold = Spreadsheet::Format.new :weight => :bold
    4.times do |x| sheet1.row(x + 1).set_format(0, bold) end
    # book.write '/Users/paolacalderon/Documents/ProyectoDaniel/excel-pacientes.xls'
    t = Time.now.strftime('%v %r')
    book.write "Pacientes-#{reporte}-#{t}.xls"
    send_file "Pacientes-#{reporte}-#{t}.xls", :type=>"application/excel", :filename => "Pacientes-#{reporte}-#{t}.xls", :stream => false
  end
end
