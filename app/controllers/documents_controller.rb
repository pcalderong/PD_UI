require 'spreadsheet'
require 'spreadsheet/excel'

class DocumentsController < ApplicationController

  def template
    send_file "#{Rails.root}/app/assets/templates/Plantilla-Importar.xls", :type=>"application/excel", :filename => "Plantilla-Importar.xls", :x_sendfile=>true, :stream => true, :disposition => 'attachment'
  end

  def export
    @personas = Persona.all
    generate_document(@personas)
  end

  def generate_document(personas)
    Spreadsheet.client_encoding = 'UTF-8'
        book = Spreadsheet::Workbook.new
        sheet1 = book.create_worksheet
        sheet1.name = 'Informacion Pacientes'
        sheet2 = book.create_worksheet
        sheet3 = book.create_worksheet
        sheet4 = book.create_worksheet
        sheet5 = book.create_worksheet
        sheet6 = book.create_worksheet
        sheet2.name = 'Informacion Contactos'
        sheet3.name = 'Informacion Extra'
        sheet4.name = 'Direccion'
        sheet5.name = 'Diagnostico'
        sheet6.name = 'Historial Medico'
        sheet1.row(0).concat %w{Nombre PrimerApellido SegundoApellido Cedula Telefono FechaNacimiento}
        sheet2.row(0).concat %w{Nombre Contacto Parentesco Telefono}
        sheet3.row(0).concat %w{Nombre Estudia Trabaja LugarEstudioTrabajo TieneHijos CantidadHijos ReferenciaTrabajoSocial AyudaAlimentos AyudaMedicamento}
        sheet4.row(0).concat %w{Nombre Provincia Canton Distrito DireccionExacta}
        sheet5.row(0).concat %w{Nombre Fecha Especialidad Padecimiento TipoPadecimiento Hospital Descripcion}
        sheet6.row(0).concat %w{Nombre Fecha EstadoActual}
        i=1
        l=1
        l1 =1;
        l2 =1;
        l3 =1;
        l4 =1;
        personas.each do |p|
          sheet1.row(i).push p.nombre, p.primer_apellido, p.segundo_apellido,
                             p.cedula.nil? ? " ":p.cedula, p.telefono.nil? ? " ":p.telefono,
                             p.fecha_nacimiento.nil? ? " ":p.fecha_nacimiento.strftime('%d/%m/%Y')
          i=i+1
          nombre = p.nombre + " " + p.primer_apellido + " " + p.segundo_apellido
          p.info_contactos.each do |ic|
            l=l+1
            sheet2.row(l).push nombre, ic.nombre_contacto.nil? ? " ": ic.nombre_contacto, ic.parentesco.nil? ? " ":ic.parentesco, ic.telefono.nil? ? " ":ic.telefono
          end
          p.info_extra_pacientes.each do |ic|
            l1=l1+1
            sheet3.row(l1).push nombre, ic.estudiante ? "Si" : "No", ic.trabajador ? "Si" : "No",
                               ic.lugar_estudio_trabajo.nil? ? " ": ic.lugar_estudio_trabajo,
                               ic.hijos ? "Si" : "No",
                               ic.cant_hijos.nil? ? " ": ic.cant_hijos,
                               ic.referencia_trab_social ? "Si" : "No",
                               ic.ayuda_alimentos ? "Si" : "No",
                               ic.ayuda_medicamento ? "Si" : "No"
          end
          p.direccions.each do |ic|
            l2=l2+1
            sheet4.row(l2).push nombre, ic.provincia.nil? ? " ": id_to_value_direccion(ic.provincia),
                               ic.canton.nil? ? " ": id_to_value_direccion(ic.canton),
                               ic.distrito.nil? ? " ": id_to_value_direccion(ic.distrito),
                               ic.direccion_exacta.nil? ? " ": ic.direccion_exacta
          end
          p.diagnosticos.each do |ic|
            l3=l3+1
            sheet5.row(l3).push nombre, ic.fecha.nil? ? " ": ic.fecha.strftime("%d-%m-%Y") ,
                               ic.especialidad_id.nil? ? " ": id_to_value_direccion(ic.especialidad_id),
                               ic.padecimiento.nil? ? " ": id_to_value_direccion(ic.padecimiento),
                               ic.tipo_padecimiento.nil? ? " ": id_to_value_direccion(ic.tipo_padecimiento),
                               ic.hospital.nil? ? " ": id_to_value_direccion(ic.hospital),
                               ic.description.nil? ? " ": ic.description
          end
          p.historial_clinicos.each do |ic|
            l4=l4+1
            sheet6.row(l4).push nombre, ic.fecha.nil? ? " ": ic.fecha.strftime("%d-%m-%Y") ,
                               ic.fk_id_lookup.nil? ? " ": id_to_value_direccion(ic.fk_id_lookup)
          end
        end

        sheet1.row(0).height = 18

        format = Spreadsheet::Format.new :color => :orange,
                                         :weight => :bold,
                                         :size => 20
        sheet1.row(0).default_format = format
        sheet2.row(0).default_format = format
        sheet3.row(0).default_format = format
        sheet4.row(0).default_format = format
        sheet5.row(0).default_format = format
        sheet6.row(0).default_format = format
        bold = Spreadsheet::Format.new :weight => :bold
        4.times do |x| sheet1.row(x + 1).set_format(0, bold) end
        # book.write '/Users/paolacalderon/Docußments/ProyectoDaniel/excel-pacientes.xls'
        t = Time.now.strftime('%v %r')
        book.write "excel-pacientes-#{t}.xls"
        send_file "excel-pacientes-#{t}.xls", :type=>"application/excel", :filename => "excel-pacientes-#{t}.xls", :stream => false
        #redirect_to personas_url
      end

  def import
  end

  def do_import
    @file = params[:file]
    book = Spreadsheet.open @file.tempfile.to_path.to_s
    # '/Users/paolacalderon/Documents/ProyectoDaniel/importar-pacientes.xls'
    sheet1 = book.worksheet 0
    sheet1.each 1 do |row|
      @persona = Persona.new
      @persona.nombre = row[0]
      @persona.primer_apellido = row[1]
      @persona.segundo_apellido = row[2]
      @persona.cedula = row[3]
      @persona.telefono = row[4]
      @persona.fecha_nacimiento = row[5]
      @persona.save
     end
    redirect_to root_path
  end

end
