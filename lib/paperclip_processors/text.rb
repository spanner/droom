module Paperclip
   # Handles extracting plain text from PDF file attachments
   class Text < Processor
     # Creates a Text extract from PDF
     def make
       src = @file
       ext = File.extname(src)
       
       if ext == '.pdf'
         
       dst = Tempfile.new([@basename, 'txt'].compact.join("."))
       command = %{
         "#{ File.expand_path(src.path) }"
         "#{ File.expand_path(dst.path) }"
       }

       begin
         success = Paperclip.run("pdftotext -nopgbrk", command.gsub(/\s+/, " "))
       rescue => e
         raise PaperclipError, "There was an error extracting text from #{@basename}"
       end
       dst
     end
   end
end
