function [journey, new_case] = tp_func_revise(retrieved_cases, new_case, new_price)
    
    retrieved_codes = retrieved_cases{:,1};
    code = str2double('-');
        
    while isnan(code) || fix(code) ~= code || ismember(code, retrieved_codes) == 0
        fprintf('From the retrieved cases, which is the one that better matches your journey?\n');
        code = str2double(input('Journey Code: ','s'));
    end
    
    journey = fix(code);

    
    %REVISE PRICE

    if new_price == -1
        fprintf('\nUpdate the price? (y/n) \n');
        option = input('Option: ','s');
        
        if option == 'y' || option == "Y"
            price = str2double('-');
            while isnan(price)
                price = str2double(input("New Price: ", "s"));
            end
            new_case.price = price;
        end
    
    else

        fprintf('\nUpdate your journey price with the new estimated value? (y/n)\n');
        option = input('Option: ', 's');
    
        if option == 'y' || option == 'Y'
            new_case.price = new_price;
        end

    end

    %REVISE NUMBER PERSONS
    fprintf("\nUpdate the number of persons? (y/n)\n");
    option = input('Option: ', "s");

    if option == 'y' || option == "Y"
        number_of_persons = str2double("-");
        while isnan(number_of_persons) || number_of_persons <= 0
            number_of_persons = str2double(input("Number of Persons: ", "s"));
        end
        new_case.number_persons = number_of_persons;
    end
    


    %REVISE REGION
    fprintf('\nUpdate the region? (y(n)\n');
    option = input("Option: ", "s");

    if option == "y" || option == "Y"
        region = "";
        while region == ""
            region = input("Region: ", "s");
        end
        new_case.region = region;
    end


    %REVISE TRANSPORTATION
    lista = {"Car", "Coach", "Plane", "Train"};

    fprintf('\nUpdate Transportation? (y(n)\n');
    option = input("Option: ", "s");

    if option == "y" || option == "Y"
        disp(lista);
        new_value = "";
        while ~ismember(lista, new_value)
            new_value = input("New value: ", "s");
        end
        new_case.transportation = new_value;
    end

    %REVISE DURATION
    fprintf('\nUpdate the duration? (y(n)\n');
    option = input("Option: ", "s");

    if option == "y" || option == "Y"
        duration = str2double("-");
        while isnan(duration)
            duration = str2double(input("Duration: ", "s"));
        end
        new_case.duration = duration;
    end


    %REVISE SEASON
    lista = {   "January", "February", "March", "April", "May", "June", "July",...
                "August", "September", "October", "November", "December"};

    fprintf('\nUpdate Season? (y(n)\n');
    option = input("Option: ", "s");
    
    if option == "y" || option == "Y"
        disp(lista);
        month = "";
        while ~ismember(lista, month)
            month = input("New value: ", "s");
        end
        new_case.transportation = month;
    end

    %REVISE ACCOMMODATION
    lista = {"FiveStars", "FourStars", "HolidayFlat", "OneStar", ...
                "ThreeStars", "TwoStars"};

    fprintf('\nUpdate Accommodation? (y(n)\n');
    option = input("Option: ", "s");

    if option == "y" || option == "Y"
        disp(lista);
        new_value = "";
        while ~ismember(lista, new_value)
            new_value = input("New value: ", "s");
        end
        new_case.transportation = new_value;
    end
end

