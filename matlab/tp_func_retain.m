function tp_func_retain(tab_case_library, struct_new_case, output_path)

    tab_new_case = struct2table(struct_new_case);
    tab_case_library = [tab_case_library; tab_new_case];

           
   fprintf('Adicionar novo caso ao dataset? (y/n)\n');
   option = input('Option: ', 's');

   if option == 'y' || option == 'Y'    
       
        writetable(tab_case_library, output_path); 
        fprintf("[Retain] Novo dataset guardado com exito.\n\n");
   end
end

