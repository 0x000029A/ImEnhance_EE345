classdef ImEnhance_exported < matlab.apps.AppBase

    % Properties that correspond to app components
    properties (Access = public)
        ImEnhanceUI        matlab.ui.Figure
        SaveButton         matlab.ui.control.Button
        MulConstSlider     matlab.ui.control.Slider
        MultiplierLabel    matlab.ui.control.Label
        SegmentButton      matlab.ui.control.Button
        EnhanceButton      matlab.ui.control.Button
        ImgNamePH          matlab.ui.control.Label
        SelectImageButton  matlab.ui.control.Button
        SgAlgDropDown      matlab.ui.control.DropDown
        SegmentationAlgorithmDropDownLabel  matlab.ui.control.Label
        EnAlgDropDown      matlab.ui.control.DropDown
        EnhancementAlgorithmDropDownLabel  matlab.ui.control.Label
        AppTitle           matlab.ui.control.Label
        LeftButton         matlab.ui.control.Button
        RightButton        matlab.ui.control.Button
        Image              matlab.ui.control.Image
        ImgHist            matlab.ui.control.UIAxes
    end

    properties (Access = private)
        img_cont % Images Container
        crnt_idx % Current index of the container
        label_cont % Labels Container
    end
    
    methods (Access = private)
        
        function print_img(app)
            app.Image.ImageSource = app.img_cont{app.crnt_idx};
            histogram(app.ImgHist, app.img_cont{app.crnt_idx});
            app.ImgNamePH.Text = app.label_cont(app.crnt_idx);
            title(app.ImgHist, [app.label_cont(app.crnt_idx) 'Histogram']);
        end
    end

    % Callbacks that handle component events
    methods (Access = private)

        % Code that executes after component creation
        function startupFcn(app)
            app.SaveButton.Enable = 'off';
            app.SegmentButton.Enable = 'off';
            app.EnhanceButton.Enable = 'off';
            app.LeftButton.Enable = 'off';
            app.RightButton.Enable = 'off';
            title(app.ImgHist,'Histogram', 'Color', 'black');
        end

        % Button pushed function: RightButton
        function RightButtonPushed(app, event)
            if isKey(app.img_cont, app.crnt_idx + 1)
                app.crnt_idx = app.crnt_idx + 1;
            elseif isKey(app.img_cont, app.crnt_idx + 2)
                app.crnt_idx = app.crnt_idx + 2;
            end
            app.print_img;
        end

        % Button pushed function: SelectImageButton
        function SelectImageButtonPushed(app, event)
            [org_img_name, org_img_location] = uigetfile({'*.png;*.jpg;*.jpeg'},'Image Selector');
            org_img_full_location = fullfile(org_img_location, org_img_name);
            app.img_cont = dictionary(1, {imread(org_img_full_location)});            
            app.crnt_idx = 1;
            app.label_cont = dictionary([1 2 3], ["Original Image" "Enhanced Image" "Segmented Image"]);
            app.print_img;
            %%%%
            app.SaveButton.Enable = 'on';
            app.SegmentButton.Enable = 'on';
            app.EnhanceButton.Enable = 'on';
            app.LeftButton.Enable = 'on';
            app.RightButton.Enable = 'on';
        end

        % Button pushed function: EnhanceButton
        function EnhanceButtonPushed(app, event)
            img_bw = rgb2gray(app.img_cont{1});
            if strcmp(app.EnAlgDropDown.Value, 'Log Transform')
                img_bw_norm = double(img_bw) ./ 255;
                img_logT = (app.MulConstSlider.Value) .* log(1 + img_bw_norm);
                app.Image.ImageSource = repmat(img_logT, 1, 1, 3);
            else
                img_th = graythresh(img_bw);
                img_bin = imbinarize(img_bw, img_th);
                app.Image.ImageSource = repmat(double(img_bin), 1, 1, 3);
            end
            app.crnt_idx = 2;
            app.img_cont(app.crnt_idx) = {app.Image.ImageSource};
            app.print_img;
        end

        % Value changed function: EnAlgDropDown
        function EnAlgDropDownValueChanged(app, event)
            value = app.EnAlgDropDown.Value;
            if strcmp(value, 'Log Transform')
                app.MulConstSlider.Enable = 'on';
            else
                app.MulConstSlider.Enable = 'off';
            end
        end

        % Button pushed function: LeftButton
        function LeftButtonPushed(app, event)
            if isKey(app.img_cont, app.crnt_idx - 1)
                app.crnt_idx = app.crnt_idx - 1;
            elseif isKey(app.img_cont, app.crnt_idx - 2)
                app.crnt_idx = app.crnt_idx - 2;
            end
            app.print_img;
        end

        % Button pushed function: SegmentButton
        function SegmentButtonPushed(app, event)
            if strcmp(app.SgAlgDropDown.Value, 'Watershed')
                img_1 = imtophat(app.img_cont{1}, strel('disk', 10));
                img_bw = im2bw(img_1, graythresh(img_1));
                dst = -bwdist(~img_bw);
                L = watershed(dst);
                L(~img_bw) = 0; 
                img_wshd = label2rgb(L, 'hot', 'w'); 
                app.Image.ImageSource = img_wshd;
            else
                class_slct_fig = figure;
                set(class_slct_fig, 'name', 'Select sample region');
                sample_regions = roipoly(app.img_cont{1});
                close(class_slct_fig);
                img_class = bsxfun(@times, app.img_cont{1}, uint8(sample_regions));
                app.Image.ImageSource = img_class;
            end
            app.crnt_idx = 3;
            app.img_cont(app.crnt_idx) = {app.Image.ImageSource};
            app.print_img;
        end

        % Button pushed function: SaveButton
        function SaveButtonPushed(app, event)
            [sv_img_name, sv_img_location] = uiputfile({'*.png;*.jpg;*.jpeg'},'Save Image');
            imwrite(app.img_cont{app.crnt_idx}, fullfile(sv_img_location, sv_img_name));
        end
    end

    % Component initialization
    methods (Access = private)

        % Create UIFigure and components
        function createComponents(app)

            % Create ImEnhanceUI and hide until all components are created
            app.ImEnhanceUI = uifigure('Visible', 'off');
            app.ImEnhanceUI.Color = [1 1 1];
            app.ImEnhanceUI.Position = [100 100 640 543];
            app.ImEnhanceUI.Name = 'ImEnhance';
            app.ImEnhanceUI.Resize = 'off';

            % Create ImgHist
            app.ImgHist = uiaxes(app.ImEnhanceUI);
            title(app.ImgHist, 'Histogram')
            xlabel(app.ImgHist, 'X')
            ylabel(app.ImgHist, 'Y')
            zlabel(app.ImgHist, 'Z')
            app.ImgHist.Toolbar.Visible = 'off';
            app.ImgHist.AmbientLightColor = [0 0 0];
            app.ImgHist.XColor = [0 0 0];
            app.ImgHist.YColor = [0 0 0];
            app.ImgHist.Color = 'none';
            app.ImgHist.Position = [30 17 590 174];

            % Create Image
            app.Image = uiimage(app.ImEnhanceUI);
            app.Image.Position = [254 273 366 205];

            % Create RightButton
            app.RightButton = uibutton(app.ImEnhanceUI, 'push');
            app.RightButton.ButtonPushedFcn = createCallbackFcn(app, @RightButtonPushed, true);
            app.RightButton.BackgroundColor = [0.502 0.502 0.502];
            app.RightButton.FontColor = [1 1 1];
            app.RightButton.Position = [505 233 46 23];
            app.RightButton.Text = '>';

            % Create LeftButton
            app.LeftButton = uibutton(app.ImEnhanceUI, 'push');
            app.LeftButton.ButtonPushedFcn = createCallbackFcn(app, @LeftButtonPushed, true);
            app.LeftButton.BackgroundColor = [0.502 0.502 0.502];
            app.LeftButton.FontColor = [1 1 1];
            app.LeftButton.Position = [310 233 48 23];
            app.LeftButton.Text = '<';

            % Create AppTitle
            app.AppTitle = uilabel(app.ImEnhanceUI);
            app.AppTitle.HorizontalAlignment = 'center';
            app.AppTitle.FontSize = 18;
            app.AppTitle.FontWeight = 'bold';
            app.AppTitle.FontColor = [1 1 1];
            app.AppTitle.Position = [136 502 370 23];
            app.AppTitle.Text = 'Image Enhancement & Segmentation Tool';

            % Create EnhancementAlgorithmDropDownLabel
            app.EnhancementAlgorithmDropDownLabel = uilabel(app.ImEnhanceUI);
            app.EnhancementAlgorithmDropDownLabel.HorizontalAlignment = 'center';
            app.EnhancementAlgorithmDropDownLabel.FontColor = [0.149 0.149 0.149];
            app.EnhancementAlgorithmDropDownLabel.Position = [30 411 79 30];
            app.EnhancementAlgorithmDropDownLabel.Text = {'Enhancement'; 'Algorithm'};

            % Create EnAlgDropDown
            app.EnAlgDropDown = uidropdown(app.ImEnhanceUI);
            app.EnAlgDropDown.Items = {'Log Transform', 'Thresholding'};
            app.EnAlgDropDown.ValueChangedFcn = createCallbackFcn(app, @EnAlgDropDownValueChanged, true);
            app.EnAlgDropDown.FontColor = [0.149 0.149 0.149];
            app.EnAlgDropDown.BackgroundColor = [0.902 0.902 0.902];
            app.EnAlgDropDown.Position = [124 419 117 22];
            app.EnAlgDropDown.Value = 'Log Transform';

            % Create SegmentationAlgorithmDropDownLabel
            app.SegmentationAlgorithmDropDownLabel = uilabel(app.ImEnhanceUI);
            app.SegmentationAlgorithmDropDownLabel.HorizontalAlignment = 'center';
            app.SegmentationAlgorithmDropDownLabel.Position = [30 273 79 30];
            app.SegmentationAlgorithmDropDownLabel.Text = {'Segmentation'; 'Algorithm'};

            % Create SgAlgDropDown
            app.SgAlgDropDown = uidropdown(app.ImEnhanceUI);
            app.SgAlgDropDown.Items = {'Watershed', 'Classifier'};
            app.SgAlgDropDown.BackgroundColor = [0.902 0.902 0.902];
            app.SgAlgDropDown.Position = [124 281 117 22];
            app.SgAlgDropDown.Value = 'Watershed';

            % Create SelectImageButton
            app.SelectImageButton = uibutton(app.ImEnhanceUI, 'push');
            app.SelectImageButton.ButtonPushedFcn = createCallbackFcn(app, @SelectImageButtonPushed, true);
            app.SelectImageButton.BackgroundColor = [0 0.1373 0.4];
            app.SelectImageButton.FontColor = [1 1 1];
            app.SelectImageButton.Position = [77 455 100 23];
            app.SelectImageButton.Text = 'Select Image';

            % Create ImgNamePH
            app.ImgNamePH = uilabel(app.ImEnhanceUI);
            app.ImgNamePH.BackgroundColor = [1 1 1];
            app.ImgNamePH.HorizontalAlignment = 'center';
            app.ImgNamePH.FontWeight = 'bold';
            app.ImgNamePH.Position = [357 233 149 22];
            app.ImgNamePH.Text = 'Image';

            % Create EnhanceButton
            app.EnhanceButton = uibutton(app.ImEnhanceUI, 'push');
            app.EnhanceButton.ButtonPushedFcn = createCallbackFcn(app, @EnhanceButtonPushed, true);
            app.EnhanceButton.BackgroundColor = [0 0.1373 0.4];
            app.EnhanceButton.FontColor = [1 1 1];
            app.EnhanceButton.Position = [77 319 100 23];
            app.EnhanceButton.Text = 'Enhance';

            % Create SegmentButton
            app.SegmentButton = uibutton(app.ImEnhanceUI, 'push');
            app.SegmentButton.ButtonPushedFcn = createCallbackFcn(app, @SegmentButtonPushed, true);
            app.SegmentButton.BackgroundColor = [0 0.1373 0.4];
            app.SegmentButton.FontColor = [1 1 1];
            app.SegmentButton.Position = [77 242 100 23];
            app.SegmentButton.Text = 'Segment';

            % Create MultiplierLabel
            app.MultiplierLabel = uilabel(app.ImEnhanceUI);
            app.MultiplierLabel.HorizontalAlignment = 'right';
            app.MultiplierLabel.Position = [9 377 53 22];
            app.MultiplierLabel.Text = 'Multiplier';

            % Create MulConstSlider
            app.MulConstSlider = uislider(app.ImEnhanceUI);
            app.MulConstSlider.Position = [83 386 150 3];
            app.MulConstSlider.Value = 1;

            % Create SaveButton
            app.SaveButton = uibutton(app.ImEnhanceUI, 'push');
            app.SaveButton.ButtonPushedFcn = createCallbackFcn(app, @SaveButtonPushed, true);
            app.SaveButton.BackgroundColor = [0 0.1373 0.4];
            app.SaveButton.FontColor = [1 1 1];
            app.SaveButton.Position = [382 198 100 23];
            app.SaveButton.Text = 'Save';

            % Show the figure after all components are created
            app.ImEnhanceUI.Visible = 'on';
        end
    end

    % App creation and deletion
    methods (Access = public)

        % Construct app
        function app = ImEnhance_exported

            % Create UIFigure and components
            createComponents(app)

            % Register the app with App Designer
            registerApp(app, app.ImEnhanceUI)

            % Execute the startup function
            runStartupFcn(app, @startupFcn)

            if nargout == 0
                clear app
            end
        end

        % Code that executes before app deletion
        function delete(app)

            % Delete UIFigure when app is deleted
            delete(app.ImEnhanceUI)
        end
    end
end