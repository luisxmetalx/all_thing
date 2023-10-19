class PruebaController < ApplicationController
    URL ='aulavirtual.espol.edu.ec'
    TOKEN = 'Bearer PxycRsmxueQ5ewkyDqhRMR4vk6eABAXr7JSEn30NR7khhTVl7zEm6vH9jiPtn144'

    def index_resumen
        response.headers.delete "X-Frame-Options"

        @id_course = 23132
        @id_quizz = 186809
        @id_submission = 1700237 

        headers = {
            # Authorization: TOKEN_NUBE
            Authorization: TOKEN
        }

        #examenes
        @quiz = Array.new
        quizz_url = "https://#{URL}/api/v1/courses/#{@id_course}/quizzes?per_page=50"
        puts quizz_url
        quizz = HTTParty.get(quizz_url, headers: headers)
        # puts quizz.length
        # puts @quizz[3]["title"].split('EXAMEN').length
        quizz.each do |quiz|
            @quiz.append(quiz)
        end

        puts "el tamanio del array es: #{@quiz.length   }"

        #submission
        loop_control = 0
        @submission = Array.new
        url_submission= "https://#{URL}/api/v1/courses/#{@id_course}/quizzes/#{@id_quizz}/submissions?per_page=50"
        #url_submission = "#{ULRCANTEST}/api/v1/courses/#{@id_course}/students/submissions?per_page=250"
        # @submission = HTTParty.get(url_submission, headers: headers)
        while loop_control == 0 do
            submission_1 = HTTParty.get(url_submission, headers: headers)
            submission_1["quiz_submissions"].each do |sutmit|
                @submission.push(sutmit)
            end
            if submission_1.headers["link"].split(",")[1].split("rel")[1].split('="')[1].split('"')[0] == "next"
                #####logger.info "entro a sumar en uno la pagina"
                url_submission = submission_1.headers["link"].split(",")[1].split("<")[1].split(">")[0]
            else
                #####logger.info "salio del loop de conteo de pagina"
                loop_control = 1
            end 
        end
        # puts @submission 

        @events = Array.new
        url_event = "https://#{URL}/api/v1/courses/#{@id_course}/quizzes/#{@id_quizz}/submissions/#{@id_submission}/events"
        # puts "la url es: #{url_event}"
        #url_submission = "#{ULRCANTEST}/api/v1/courses/#{@id_course}/students/submissions?per_page=250"
        # @submission = HTTParty.get(url_submission, headers: headers)
        loop_control = 0
        @questions = Array.new
        while loop_control == 0 do
            event_1 = HTTParty.get(url_event, headers: headers)
            # puts "los eventos son: #{event_1}"
            event_1["quiz_submission_events"].each do |evento|
                @events.push(evento)
            end
            if event_1.headers["link"].split(",")[1].split("rel")[1].split('="')[1].split('"')[0] == "next"
                #####logger.info "entro a sumar en uno la pagina"
                url_event = event_1.headers["link"].split(",")[1].split("<")[1].split(">")[0]
            else
                #####logger.info "salio del loop de conteo de pagina"
                loop_control = 1
            end 
        end

        # puts @events
        # raise "espere mientras se modifica los errores"

        #sacar las respustas de las pregutnas y el mismo evento del usuario
        @answer = Array.new
        @nombres_preguntas = Array.new
        @events[0]["event_data"]["quiz_data"].each_with_index do |question, index_preguntas|
            # @nombres_preguntas.push(question["question_text"])
            begin
                @events.each_with_index do |evento, index_evento|
                    puts "el indice fue: #{index_evento}"
                    if index_evento > 1
                        if evento["event_type"] == "question_viewed" || evento["event_type"] == "page_focused"
                            # raise "#{evento["event_type"]} con indice #{index_evento} y con data #{@events[index_evento]}"
                            @events.delete_at(index_evento)
                        end
                        puts "el tamanio del arreglo es: #{evento["event_data"].length} y #{evento["event_type"]}"
                        if evento["event_data"].length == 1
                            puts "-- entro porque tiene un solo tamanio --"
                            if (question["question_type"] == "essay_question" || question["question_type"] == "multiple_choice_question") && question["id"] ==  evento["event_data"][0]["quiz_question_id"].to_i
                                if question["question_type"] == "multiple_choice_question"
                                    question["answers"].each do |a|
                                        if a["id"].to_i == evento["event_data"][0]["answer"].to_i
                                            answ = a["text"]
                                        end
                                    end
                                else
                                    answ = evento["event_data"][0]["answer"]
                                end
                                
                                data ={
                                    :id_submission => evento["id"],
                                    :id => question["id"],
                                    :n_pregunta => question["question_text"],
                                    :data => answ
                                }
                                @answer.append(data)    
                                # raise "#{evento["event_data"][0]["answer"]} y #{@answer}"
                                puts "** GUARDO LA INFORMACION **"
                                puts "***************************"
                                puts "el tamnio de eventos es #{@events.length}"
                                @events.delete_at(index_evento)
                                puts "el tamnio de eventos es #{@events.length}"
                                
                                break
                            end
                        end
                        if evento["event_data"].length > 1
                            puts "-- entro porque tiene un tamanio de mas de uno --"
                            evento["event_data"].each do |answ|
                                if (question["question_type"] == "essay_question" || question["question_type"] == "multiple_choice_question") && question["id"] ==  answ["quiz_question_id"].to_i
                                    if question["question_type"] == "multiple_choice_question"
                                        question["answers"].each do |a|
                                            # raise "respuestas #{a} y donde #{answ["answer"].to_i}"
                                            if a["id"].to_i == answ["answer"].to_i
                                                answ = a["text"]
                                            end
                                        end
                                    else
                                        answ = answ["answer"]
                                    end
                                    
                                    data ={
                                        :id_submission => evento["id"],
                                        :id_quizz => question["id"],
                                        :n_pregunta => question["question_text"],
                                        :data => answ
                                    }
                                    @answer.append(data)  
                                    # raise "#{answ} el id de la pregunta es #{question["id"]} el tipo de la pregunta es #{question["question_type"]} y la respuesta es #{@answer}"
                                    puts "** GUARDO LA INFORMACION **"
                                    puts "***************************"
                                    @events.delete_at(index_evento)
                                    break
                                end
                            end
                        end
                    end
                end
            rescue NoMethodError
                p @events.length
            else
                p "todo bien de momento"
            end
        end
        
        # render json: @events
        # render json: @nombres_preguntas
        # render json: @answer
        respond_to do |format|
            format.html
            # format.pdf {render :pdf => 'formulario_relex', :template => 'resumen_evaluacion/index_resumen.html.erb'}
            format.pdf do
              render pdf: "formulario_relex" ,template: 'resumen_evaluacion/index_resumen.html.erb' # Excluding ".pdf" extension.
            end
          end
    end
end
