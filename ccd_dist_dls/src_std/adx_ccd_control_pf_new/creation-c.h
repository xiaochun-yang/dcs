/*
 * WARNING: This file is overwritten at code generation time.
 * Any changes to this file will be lost.
 */
/*
 *
 * Created by Builder Xcessory 4.0
 * Generated by Code Generator Xcessory 2.0 (09/09/96)
 *
 */
#ifndef creation_c_H
#define creation_c_H
#define SAVE_TIFF 3
#define MC_PHI 1
#define Magnification_8 1
#define GONIO_COMPUTER 1
#define SAVE_METHOD 1
#define SAVE_LINE 2
#define SAVE_POSTSCRIPT 2
#define EXIT_ALL 3
#define STOP_NO 1
#define PLOT_PIXEL 2
#define HELP_STATISTICS 6
#define INIT_NO 1
#define SORT_ALPHABETICALLY 1
#define EXIT_NO 0
#define SPOT_INFO 3
#define MC_OFFSET 2
#define Magnification_32 3
#define Magnification_4 0
#define DOWN_ARROW 1
#define Magnification_64 4
#define Scale_Auto 3
#define SPOT_ADD 1
#define EXIT_HELP 2
#define OPTIMIZE_INDEX 0
#define bg32x32bitmap	bg32x32bitmap_icon
static char * bg32x32bitmap_icon[] = {
"32 32 1 1",
". c #000",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................",
"................................"
};
#define Magnification_16 2
#define PLOT_LINE 1
#define NO 0
#define HELP_SLICE 0
#define HELP_IMAGE 2
#define BEAM_PIXELS 1
#define GRAYSCALE 1
#define HELP_MAGNIFY 3
#define CURRENT_IMAGE 0
#define STOP_YES 0
#define MC_DISTANCE 0
#define COLOR2 2
#define PHI_90 0
#define PHI_180 1
#define PHI_0 2
#define PHI_270 3
#define INIT_YES 0
#define EXIT_YES 1
#define EXIT_MANAGE 2
#define PLOT_DOT 0
#define SAVE_BINARY 1
#define DELETE_METHOD 2
#define FOLLOW_IMAGES 1
#define SELECT_IMAGE 2
#define INDEX_H 1
#define INDEX_K 2
#define SORT_BY_TIME 0
#define SAVE_IMAGE 0
#define SPOT_REMOVE 2
#define MC_WAVELENGTH 5
#define MC_ENERGY 6
#define BEAM_MM 0
#define INDEX_L 3
#define HELP_CONTROL 1
#define SPOT_ISIGMA 5
#define MC_KAPPA 3
#define MC_OMEGA 4
#define Mag_Values 0
#define Mag_Pixels 1
#define SUB_ORIG 0
#define Mag_3D 2
#define SAVE_ASCII 0
#define HELP_SAVE 4
#define xrayoffbitmap	xrayoffbitmap_icon
static char * xrayoffbitmap_icon[] = {
"32 32 2 1",
". c #ffffefefd7d7",
"X c #ffffc7c79696",
"................................",
"................................",
"................................",
"........XX.............XX.......",
"......XXXX.............XXXX.....",
".....XXXXX.............XXXXX....",
".....XXXXXX...........XXXXXXX...",
"....XXXXXXX...........XXXXXXX...",
"...XXXXXXXXX.........XXXXXXXXX..",
"...XXXXXXXXX.........XXXXXXXXX..",
"..XXXXXXXXXXX.......XXXXXXXXXXX.",
"..XXXXXXXXXX.........XXXXXXXXXX.",
".XXXXXXXXXX...XXXXX...XXXXXXXXXX",
".XXXXXXXXXX..XXXXXXX..XXXXXXXXXX",
".XXXXXXXXX..XXXXXXXXX..XXXXXXXXX",
".XXXXXXXXX..XXXXXXXXX..XXXXXXXXX",
".XXXXXXXXX..XXXXXXXXX..XXXXXXXXX",
"............XXXXXXXXX...........",
".............XXXXXXX............",
"..............XXXXX.............",
"................................",
".............X.....X............",
"............XXXXXXXXX...........",
"............XXXXXXXXX...........",
"...........XXXXXXXXXXX..........",
"..........XXXXXXXXXXXXX.........",
"..........XXXXXXXXXXXXX.........",
".........XXXXXXXXXXXXXXX........",
"........XXXXXXXXXXXXXXXXX.......",
"........XXXXXXXXXXXXXXXXX.......",
"..........XXXXXXXXXXXXX.........",
"............XXXXXXXXX..........."
};
#define Scale_100 0
#define OPTIMIZE_CALCULATE 1
#define xraybitmap	xraybitmap_icon
static char * xraybitmap_icon[] = {
"32 32 2 1",
". c #ffffffff0000",
"X c #ffff30303030",
"................................",
"................................",
"................................",
"........XX.............XX.......",
"......XXXX.............XXXX.....",
".....XXXXX.............XXXXX....",
".....XXXXXX...........XXXXXXX...",
"....XXXXXXX...........XXXXXXX...",
"...XXXXXXXXX.........XXXXXXXXX..",
"...XXXXXXXXX.........XXXXXXXXX..",
"..XXXXXXXXXXX.......XXXXXXXXXXX.",
"..XXXXXXXXXX.........XXXXXXXXXX.",
".XXXXXXXXXX...XXXXX...XXXXXXXXXX",
".XXXXXXXXXX..XXXXXXX..XXXXXXXXXX",
".XXXXXXXXX..XXXXXXXXX..XXXXXXXXX",
".XXXXXXXXX..XXXXXXXXX..XXXXXXXXX",
".XXXXXXXXX..XXXXXXXXX..XXXXXXXXX",
"............XXXXXXXXX...........",
".............XXXXXXX............",
"..............XXXXX.............",
"................................",
".............X.....X............",
"............XXXXXXXXX...........",
"............XXXXXXXXX...........",
"...........XXXXXXXXXXX..........",
"..........XXXXXXXXXXXXX.........",
"..........XXXXXXXXXXXXX.........",
".........XXXXXXXXXXXXXXX........",
"........XXXXXXXXXXXXXXXXX.......",
"........XXXXXXXXXXXXXXXXX.......",
"..........XXXXXXXXXXXXX.........",
"............XXXXXXXXX..........."
};
#define HELP_BACKGROUND 5
#define YES 1
#define SPOT_NUMBER 4
#define PROCESS_MOSFLM 3
#define GONIO_MANUAL 0
#define PROCESS_AUTOINDEX 0
#define PFSTARS_CONTROL 0
#define Scale_50 1
#define COLOR 0
#define SUB_DISP 1
#define PROCESS_XDS 1
#define PROCESS_DENZO 2
#define UP_ARROW 0
#define LOAD_METHOD 0
#define Scale_25 2
#define SAVE_MAGNIFY 1

/*
 * Global widget declarations.
 *        - EXTERNAL is set to extern if the
 *          defs file is not included from the
 *          main file.
 */
#ifdef DECLARE_BX_GLOBALS
#define EXTERNAL
#else
#define EXTERNAL extern
#endif

/*
 * Start Global Widget Declarations.
 */
EXTERNAL Widget   configsiteDialog;
EXTERNAL Widget   configsite_textVal10;
EXTERNAL Widget   configsite_textVal9;
EXTERNAL Widget   configsite_textVal8;
EXTERNAL Widget   configsite_textVal7;
EXTERNAL Widget   configsite_textVal6;
EXTERNAL Widget   configsite_textVal5;
EXTERNAL Widget   configsite_textVal4;
EXTERNAL Widget   configsite_textVal3;
EXTERNAL Widget   configsite_textVal2;
EXTERNAL Widget   configsite_textKey8;
EXTERNAL Widget   configsite_textKey10;
EXTERNAL Widget   configsite_textKey9;
EXTERNAL Widget   configsite_textKey7;
EXTERNAL Widget   configsite_textKey6;
EXTERNAL Widget   configsite_textKey5;
EXTERNAL Widget   configsite_textKey4;
EXTERNAL Widget   configsite_textKey3;
EXTERNAL Widget   configsite_textKey2;
EXTERNAL Widget   configsite_textVal1;
EXTERNAL Widget   configsite_textKey1;
EXTERNAL Widget   project_dialog;
EXTERNAL Widget   project_param_file_textField;
EXTERNAL Widget   project_spgrp_textField;
EXTERNAL Widget   project_i_prefix_textField;
EXTERNAL Widget   project_proc_dir_textField;
EXTERNAL Widget   project_data_dir_textField;
EXTERNAL Widget   define_kappa_Dialog;
EXTERNAL Widget   define_omega_Dialog;
EXTERNAL Widget   optimize_add_fSB;
EXTERNAL Widget   localSiteDialog;
EXTERNAL Widget   wavelength_textField;
EXTERNAL Widget   localSite_button1;
EXTERNAL Widget   localSite_label1;
EXTERNAL Widget   weakbeamDialog;
EXTERNAL Widget   weakbeam_label2;
EXTERNAL Widget   nobeamDialog;
EXTERNAL Widget   nobeam_label2;
EXTERNAL Widget   mcinfoDialog;
EXTERNAL Widget   diskfullDialog;
EXTERNAL Widget   disk_full_label2;
EXTERNAL Widget   disk_full_label1;
EXTERNAL Widget   disk_full_label;
EXTERNAL Widget   error_Dialog;
EXTERNAL Widget   error_Dialog_text;
EXTERNAL Widget   error_pushButton;
EXTERNAL Widget   abortDialog;
EXTERNAL Widget   pushButton18;
EXTERNAL Widget   delete_method_fSB;
EXTERNAL Widget   save_method_fSB;
EXTERNAL Widget   load_method_fSB;
EXTERNAL Widget   exitDialog;
EXTERNAL Widget   pushButton220;
EXTERNAL Widget   pushButton9;
EXTERNAL Widget   strategyDialog;
EXTERNAL Widget   strategy_MAD_mode;
EXTERNAL Widget   strategy_MADno_toggleButton;
EXTERNAL Widget   strategy_MADyes_toggleButton;
EXTERNAL Widget   strategy_comp_none_toggleButton;
EXTERNAL Widget   strategy_comp_pck_toggleButton;
EXTERNAL Widget   strategy_comp_Z_toggleButton;
EXTERNAL Widget   label29;
EXTERNAL Widget   strategy_wedge_textField;
EXTERNAL Widget   label18;
EXTERNAL Widget   strategy_anomno_toggleButton;
EXTERNAL Widget   strategy_anomyes_toggleButton;
EXTERNAL Widget   strategy_beamy_textField;
EXTERNAL Widget   strategy_beamx_textField;
EXTERNAL Widget   pushButton170;
EXTERNAL Widget   pushButton171;
EXTERNAL Widget   pushButton172;
EXTERNAL Widget   pushButton173;
EXTERNAL Widget   pushButton174;
EXTERNAL Widget   pushButton175;
EXTERNAL Widget   pushButton176;
EXTERNAL Widget   pushButton177;
EXTERNAL Widget   pushButton162;
EXTERNAL Widget   pushButton163;
EXTERNAL Widget   pushButton164;
EXTERNAL Widget   pushButton165;
EXTERNAL Widget   pushButton166;
EXTERNAL Widget   pushButton167;
EXTERNAL Widget   pushButton168;
EXTERNAL Widget   pushButton169;
EXTERNAL Widget   beamline_label;
EXTERNAL Widget   bl_scrolledwindow;
EXTERNAL Widget   beamline_list;
EXTERNAL Widget   scrolledWindow1;
EXTERNAL Widget   runtext;
EXTERNAL Widget   strategy_time_dose_label;
EXTERNAL Widget   pushButton60;
EXTERNAL Widget   pushButton61;
EXTERNAL Widget   pushButton62;
EXTERNAL Widget   pushButton63;
EXTERNAL Widget   pushButton64;
EXTERNAL Widget   pushButton65;
EXTERNAL Widget   pushButton66;
EXTERNAL Widget   pushButton67;
EXTERNAL Widget   strategy_comment_textField;
EXTERNAL Widget   strategy_collect_Pushbutton;
EXTERNAL Widget   menuBar;
EXTERNAL Widget   strategy_close_pushbutton;
EXTERNAL Widget   strategy_time_mode_toggleButton;
EXTERNAL Widget   strategy_dose_mode_toggleButton;
EXTERNAL Widget   strategy_image_prefix_textField;
EXTERNAL Widget   strategy_directory_textField;
EXTERNAL Widget   statusDialog;
EXTERNAL Widget   status_adc_label;
EXTERNAL Widget   step_kappa_label;
EXTERNAL Widget   status_label_kappa;
EXTERNAL Widget   step_omega_label;
EXTERNAL Widget   status_label_omega;
EXTERNAL Widget   kappa_textField;
EXTERNAL Widget   omega_textField;
EXTERNAL Widget   status_label_2theta;
EXTERNAL Widget   status_label_offset;
EXTERNAL Widget   status_label_phi;
EXTERNAL Widget   speed_textField;
EXTERNAL Widget   binning_textField;
EXTERNAL Widget   disk_space_images_textField;
EXTERNAL Widget   disk_space_mb_textField;
EXTERNAL Widget   directory_textField;
EXTERNAL Widget   xray_off_label2;
EXTERNAL Widget   xray_on_label2;
EXTERNAL Widget   dose_time_label;
EXTERNAL Widget   intensity_textField;
EXTERNAL Widget   status_shutter_label;
EXTERNAL Widget   completion_all_textField;
EXTERNAL Widget   completion_this_textField;
EXTERNAL Widget   step_phi_label;
EXTERNAL Widget   delta_phi_textField;
EXTERNAL Widget   image_textField;
EXTERNAL Widget   offset_textField;
EXTERNAL Widget   curr_phi_textField;
EXTERNAL Widget   exp_time_textField;
EXTERNAL Widget   distance_textField;
EXTERNAL Widget   expose_scale;
EXTERNAL Widget   status_message;
EXTERNAL Widget   xray_off_label;
EXTERNAL Widget   xray_on_label;
EXTERNAL Widget   snapshotDialog;
EXTERNAL Widget   snap_adc_label;
EXTERNAL Widget   snap_dez_yes_toggleButton;
EXTERNAL Widget   snap_dez_no_toggleButton;
EXTERNAL Widget   snap_label_start_phi;
EXTERNAL Widget   snapshot_axis;
EXTERNAL Widget   snap_axisOmega_toggleButton;
EXTERNAL Widget   snap_axisPhi_toggleButton;
EXTERNAL Widget   snap_label_delta_omega;
EXTERNAL Widget   snap_label_start_omega;
EXTERNAL Widget   snap_ydc_toggleButton;
EXTERNAL Widget   snap_ndc_toggleButton;
EXTERNAL Widget   snap_bin1_toggleButton;
EXTERNAL Widget   snap_bin2_toggleButton;
EXTERNAL Widget   snap_label_delta_phi;
EXTERNAL Widget   snap_offset_label;
EXTERNAL Widget   snap_offset_textField;
EXTERNAL Widget   snap_slow_toggleButton;
EXTERNAL Widget   snap_fast_toggleButton;
EXTERNAL Widget   snapshot_pushButton;
EXTERNAL Widget   snap_step_size_textField;
EXTERNAL Widget   snap_phi_textField;
EXTERNAL Widget   pushButton121;
EXTERNAL Widget   pushButton122;
EXTERNAL Widget   pushButton123;
EXTERNAL Widget   pushButton124;
EXTERNAL Widget   pushButton125;
EXTERNAL Widget   pushButton126;
EXTERNAL Widget   pushButton127;
EXTERNAL Widget   pushButton128;
EXTERNAL Widget   snap_exposure_time_textField;
EXTERNAL Widget   snap_distance_textField;
EXTERNAL Widget   snap_image_textField;
EXTERNAL Widget   snap_directory_textField;
EXTERNAL Widget   manual_controlDialog;
EXTERNAL Widget   modify_wavelength_textField;
EXTERNAL Widget   drive_wavelength_pushButton;
EXTERNAL Widget   define_wavelength_pushButton;
EXTERNAL Widget   gonio_home_pushbutton;
EXTERNAL Widget   gonio_off_pushButton;
EXTERNAL Widget   gonio_on_pushButton;
EXTERNAL Widget   modify_omega_textField;
EXTERNAL Widget   pushButton189;
EXTERNAL Widget   pushButton190;
EXTERNAL Widget   pushButton191;
EXTERNAL Widget   pushButton192;
EXTERNAL Widget   pushButton193;
EXTERNAL Widget   pushButton194;
EXTERNAL Widget   pushButton195;
EXTERNAL Widget   pushButton196;
EXTERNAL Widget   mc_omega_apply;
EXTERNAL Widget   drive_omega_pushButton;
EXTERNAL Widget   define_omega_pushButton;
EXTERNAL Widget   modify_kappa_textField;
EXTERNAL Widget   pushButton179;
EXTERNAL Widget   pushButton181;
EXTERNAL Widget   pushButton183;
EXTERNAL Widget   pushButton184;
EXTERNAL Widget   pushButton185;
EXTERNAL Widget   pushButton186;
EXTERNAL Widget   pushButton187;
EXTERNAL Widget   pushButton188;
EXTERNAL Widget   mc_kappa_apply;
EXTERNAL Widget   drive_kappa_pushButton;
EXTERNAL Widget   define_kappa_pushButton;
EXTERNAL Widget   mc_offset_apply;
EXTERNAL Widget   mc_phi_apply;
EXTERNAL Widget   mc_distance_apply;
EXTERNAL Widget   driveby_label;
EXTERNAL Widget   driveto_label;
EXTERNAL Widget   driveby_form;
EXTERNAL Widget   drive_phi180_pushButton;
EXTERNAL Widget   drive_phi90_pushButton;
EXTERNAL Widget   driveto_form;
EXTERNAL Widget   driveto_phi180_pushButton;
EXTERNAL Widget   driveto_phi90_pushButton;
EXTERNAL Widget   driveto_phi0_pushButton;
EXTERNAL Widget   driveto_phi270_pushButton;
EXTERNAL Widget   mc_offset_label;
EXTERNAL Widget   mc_shutter_button;
EXTERNAL Widget   mc_offset_radiobox;
EXTERNAL Widget   drive_twotheta_pushButton;
EXTERNAL Widget   define_twotheta_pushButton;
EXTERNAL Widget   modify_offset_textField;
EXTERNAL Widget   drive_phi_pushButton;
EXTERNAL Widget   define_phi_pushButton;
EXTERNAL Widget   modify_phi_textField;
EXTERNAL Widget   pushButton96;
EXTERNAL Widget   pushButton97;
EXTERNAL Widget   pushButton98;
EXTERNAL Widget   pushButton99;
EXTERNAL Widget   pushButton100;
EXTERNAL Widget   pushButton101;
EXTERNAL Widget   pushButton102;
EXTERNAL Widget   pushButton103;
EXTERNAL Widget   drive_distance_pushButton;
EXTERNAL Widget   define_distance_pushButton;
EXTERNAL Widget   modify_distance_textField;
EXTERNAL Widget   define_distance_Dialog;
EXTERNAL Widget   pushButton2;
EXTERNAL Widget   stopDialog;
EXTERNAL Widget   pushButton4;
EXTERNAL Widget   pushButton5;
EXTERNAL Widget   define_phi_Dialog;
EXTERNAL Widget   pushButton11;
EXTERNAL Widget   define_offset_Dialog;
EXTERNAL Widget   pushButton12;
EXTERNAL Widget   restartRun_dialog;
EXTERNAL Widget   strategy_restart_Pushbutton1;
EXTERNAL Widget   strategy_restart_Pushbutton;
EXTERNAL Widget   restart_frame_textfield;
EXTERNAL Widget   restart_run_textfield;
EXTERNAL Widget   versionDialog;
EXTERNAL Widget   optimize_dialog;
EXTERNAL Widget   optimize_apply_Pushbutton1;
EXTERNAL Widget   optimimal_runs_text;
EXTERNAL Widget   optimize_maxrunsize_textField;
EXTERNAL Widget   optimize_merge_yes;
EXTERNAL Widget   optimize_merge_no;
EXTERNAL Widget   optimize_resmax_textField;
EXTERNAL Widget   optimize_res2_textField;
EXTERNAL Widget   optimize_res1_textField;
EXTERNAL Widget   optimize_param_file_list;
EXTERNAL Widget   optimize_param_file_textField;
EXTERNAL Widget   adx_helpDialog;
EXTERNAL Widget   config_site_helpWindow;
EXTERNAL Widget   mad_helpWindow;
EXTERNAL Widget   options_helpWindow;
EXTERNAL Widget   project_helpWindow;
EXTERNAL Widget   status_helpWindow;
EXTERNAL Widget   snapshot_helpWindow;
EXTERNAL Widget   strategy_helpWindow;
EXTERNAL Widget   optimize_helpWindow;
EXTERNAL Widget   manualcontrol_helpWindow;
EXTERNAL Widget   alertDialog;
EXTERNAL Widget   alert_label;
EXTERNAL Widget   optionsDialog;
EXTERNAL Widget   options_darkinterval_textField;
EXTERNAL Widget   options_deg_dose_textField;
EXTERNAL Widget   options_outputsmv_toggleButton;
EXTERNAL Widget   options_outputcbf_toggleButton;
EXTERNAL Widget   options_xform_yes;
EXTERNAL Widget   options_xform_no;
EXTERNAL Widget   options_saveraw_yes;
EXTERNAL Widget   options_saveraw_no;
EXTERNAL Widget   options_step_textField;
EXTERNAL Widget   label32;
EXTERNAL Widget   options_darkrun_toggleButton;
EXTERNAL Widget   options_darkinterval_toggleButton;
EXTERNAL Widget   options_darkstored_toggleButton;
EXTERNAL Widget   strategy_bin1_toggleButton;
EXTERNAL Widget   strategy_bin2_toggleButton;
EXTERNAL Widget   strategy_slow_toggleButton;
EXTERNAL Widget   strategy_fast_toggleButton;
EXTERNAL Widget   strategy_adc_label;
EXTERNAL Widget   options_output16_toggleButton;
EXTERNAL Widget   options_output32_toggleButton;
EXTERNAL Widget   madDialog;
EXTERNAL Widget   label109;
EXTERNAL Widget   mad_nframes_textField;
EXTERNAL Widget   label108;
EXTERNAL Widget   mad_option1_toggleButton;
EXTERNAL Widget   mad_option2_toggleButton;
EXTERNAL Widget   mad_option3_toggleButton;
EXTERNAL Widget   mad_option4_toggleButton;
EXTERNAL Widget   label97;
EXTERNAL Widget   energy5_textField;
EXTERNAL Widget   wavelength5_textField;
EXTERNAL Widget   energy4_textField;
EXTERNAL Widget   wavelength4_textField;
EXTERNAL Widget   energy3_textField;
EXTERNAL Widget   wavelength3_textField;
EXTERNAL Widget   energy2_textField;
EXTERNAL Widget   wavelength2_textField;
EXTERNAL Widget   energy1_textField;
EXTERNAL Widget   wavelength1_textField;
EXTERNAL Widget   enable_wavelength1_toggleButton;
EXTERNAL Widget   enable_wavelength2_toggleButton;
EXTERNAL Widget   enable_wavelength3_toggleButton;
EXTERNAL Widget   enable_wavelength4_toggleButton;
EXTERNAL Widget   enable_wavelength5_toggleButton;
EXTERNAL Widget   bulletinBoard;
EXTERNAL Widget   process_arrowButton;
EXTERNAL Widget   display_arrowButton;
EXTERNAL Widget   stop_arrowButton;
EXTERNAL Widget   setup_arrowButton;
EXTERNAL Widget   exitButton;
EXTERNAL Widget   processButton;
EXTERNAL Widget   process_popupMenu;
EXTERNAL Widget   autoindexButton;
EXTERNAL Widget   xdsButton;
EXTERNAL Widget   denzoButton;
EXTERNAL Widget   mosflmButton;
EXTERNAL Widget   displayButton;
EXTERNAL Widget   display_popupMenu;
EXTERNAL Widget   stopButton;
EXTERNAL Widget   popupMenu;
EXTERNAL Widget   setupButton;
EXTERNAL Widget   setup_popupMenu;

/*
 *	Added externals not generated by BX
 */

EXTERNAL Widget	  stopnowButton;

/* PF start */

#define	MAX_ATTENUATORS	10
#define	MAX_CLIENTS	20

EXTERNAL char	  saved_atten_names[MAX_ATTENUATORS][20];
EXTERNAL char	  saved_client_names[MAX_CLIENTS][80];

EXTERNAL Widget   snap_axis_label;
EXTERNAL Widget   snap_energy_label;
EXTERNAL Widget   snap_wave_label;
EXTERNAL Widget   snap_energy_textField;
EXTERNAL Widget   snap_wave_textField;
EXTERNAL Widget   mc_modify_energy_textField;
EXTERNAL Widget   mc_energy_apply;
EXTERNAL Widget   mc_energy_label;
EXTERNAL Widget   mc_energy_radioBox;
EXTERNAL Widget   mc_wavelength_radioBox;
EXTERNAL Widget   drive_energy_pushButton;
EXTERNAL Widget   define_energy_pushButton;
EXTERNAL Widget   mc_atten_button;
EXTERNAL Widget   mc_atten_pulldownMenu;
EXTERNAL Widget   mc_atten_buttons[MAX_ATTENUATORS];
EXTERNAL Widget   stars_clientlist_buttons[MAX_CLIENTS];
EXTERNAL int      mc_n_atten_buttons;
EXTERNAL int      stars_n_client_buttons;
EXTERNAL Widget   status_label_energy;
EXTERNAL Widget   status_label_wavelength;
EXTERNAL Widget   status_energy_textField;
EXTERNAL Widget   status_wavelength_textField;
EXTERNAL Widget   status_adsc_slit_wavelength_label;
EXTERNAL Widget   status_adsc_slit_wavelength_textField;
EXTERNAL Widget   strategy_autoal_label;
EXTERNAL Widget   strategy_autoalevery_mode;
EXTERNAL Widget   strategy_autoaleveryno_toggleButton;
EXTERNAL Widget   strategy_autoaleveryyes_toggleButton;
EXTERNAL Widget   strategy_slit_label;
EXTERNAL Widget   strategy_hslit_label;
EXTERNAL Widget   strategy_vslit_label;
EXTERNAL Widget   strategy_hslit_textField;
EXTERNAL Widget   strategy_vslit_textField;
EXTERNAL Widget   strategy_kappa_label;
EXTERNAL Widget   strategy_phi_label;
EXTERNAL Widget   strategy_energy_label;
EXTERNAL Widget	  strategy_energy_popupMenu;
EXTERNAL Widget   strategy_energy_sw_to_wave_pushButton;
EXTERNAL Widget   strategy_energy_use_current_pushButton;
EXTERNAL Widget   strategy_wave_label;
EXTERNAL Widget	  strategy_wave_popupMenu;
EXTERNAL Widget   strategy_wave_sw_to_energy_pushButton;
EXTERNAL Widget   strategy_wave_use_current_pushButton;
EXTERNAL Widget   strategy_atten_label;
EXTERNAL Widget	  mc_drive_phi_radioBox;
EXTERNAL Widget	  mc_drive_kappa_radioBox;
EXTERNAL Widget	  mc_drive_phi_label;
EXTERNAL Widget	  mc_drive_kappa_label;
EXTERNAL Widget   mc_autoal_form;
EXTERNAL Widget   mc_autoal_start_pushButton;
EXTERNAL Widget   mc_autoal_stop_pushButton;
EXTERNAL Widget   mc_autoal_undo_pushButton;
EXTERNAL Widget   mc_autoal_label;
EXTERNAL Widget   mc_autoal_slit_label;
EXTERNAL Widget   mc_autoal_slit_textField;
EXTERNAL Widget   mc_vs_textField;
EXTERNAL Widget   mc_hs_textField;

EXTERNAL Widget   mc_em_label;
EXTERNAL Widget   mc_em_dc_apply_pushButton;
EXTERNAL Widget   mc_em_cc_apply_pushButton;
EXTERNAL Widget   mc_em_lm_apply_pushButton;
EXTERNAL Widget   mc_em_xafsm_apply_pushButton;
EXTERNAL Widget   status_label_master;
EXTERNAL Widget   status_label_em_other;
EXTERNAL Widget   status_label_em_db;
EXTERNAL Widget   status_label_em_gsa;
EXTERNAL Widget   status_label_em_fbsa;
EXTERNAL Widget   status_label_em_rbsa;
EXTERNAL Widget   status_label_em_lm;
EXTERNAL Widget   status_label_em_cc;
EXTERNAL Widget   status_label_em_xafsm;
EXTERNAL Widget   status_label_em_dc;
EXTERNAL Widget   status_label_attenuator;
EXTERNAL Widget   status_master_textField;
EXTERNAL Widget   status_label_hslit;
EXTERNAL Widget   status_label_vslit;
EXTERNAL Widget   status_attenuator_textField;
EXTERNAL Widget   status_hslit_textField;
EXTERNAL Widget   status_vslit_textField;

EXTERNAL Widget	  pfstarsButton;

EXTERNAL Widget   stars_dialog;
EXTERNAL Widget	  stars_master_label;
EXTERNAL Widget	  stars_master_textField;
EXTERNAL Widget   stars_for_adsc_label;
EXTERNAL Widget   stars_for_any_label;
EXTERNAL Widget	  stars_make_adsc_master_pushButton;
EXTERNAL Widget   stars_make_none_master_pushButton;
EXTERNAL Widget   stars_make_any_menuBar;
EXTERNAL Widget   stars_make_any_cascadeButton;
EXTERNAL Widget   stars_make_any_master_pulldownMenu;

EXTERNAL Widget   stars_param_file_textField;
EXTERNAL Widget   stars_spgrp_textField;
EXTERNAL Widget   stars_i_prefix_textField;
EXTERNAL Widget   stars_proc_dir_textField;
EXTERNAL Widget   stars_data_dir_textField;
EXTERNAL Widget   stars_helpWindow;

/* PF End */

/* ADSC_SLIT Start */

EXTERNAL Widget   mc_v_up_halfslit_label;
EXTERNAL Widget   mc_v_up_halfslit_radioBox;
EXTERNAL Widget   mc_v_up_halfslit_out_pushButton;
EXTERNAL Widget   mc_v_up_halfslit_in_pushButton;
EXTERNAL Widget   mc_h_up_halfslit_label;
EXTERNAL Widget   mc_h_up_halfslit_radioBox;
EXTERNAL Widget   mc_h_up_halfslit_out_pushButton;
EXTERNAL Widget   mc_h_up_halfslit_in_pushButton;

EXTERNAL Widget   mc_v_dn_halfslit_label;
EXTERNAL Widget   mc_v_dn_halfslit_radioBox;
EXTERNAL Widget   mc_v_dn_halfslit_out_pushButton;
EXTERNAL Widget   mc_v_dn_halfslit_in_pushButton;
EXTERNAL Widget   mc_h_dn_halfslit_label;
EXTERNAL Widget   mc_h_dn_halfslit_radioBox;
EXTERNAL Widget   mc_h_dn_halfslit_out_pushButton;
EXTERNAL Widget   mc_h_dn_halfslit_in_pushButton;

EXTERNAL Widget	  mc_up_ion_textField;
EXTERNAL Widget	  mc_dn_ion_textField;
EXTERNAL Widget	  mc_beam_ion_textField;

EXTERNAL Widget   mc_ion_chamber_label;
EXTERNAL Widget   mc_ion_chamber2_label;

/* ADSC_SLIT and PF */

EXTERNAL Widget   mc_beam_defining_aperature_label;
EXTERNAL Widget   mc_vs_radioBox;
EXTERNAL Widget   mc_hs_radioBox;
EXTERNAL Widget   mc_vs_drive_pushButton;
EXTERNAL Widget   mc_hs_drive_pushButton;
EXTERNAL Widget   mc_hs_apply_pushButton;
EXTERNAL Widget   mc_vs_apply_pushButton;
EXTERNAL Widget   mc_vs_zero_pushButton;
EXTERNAL Widget   mc_hs_zero_pushButton;
EXTERNAL Widget   mc_vs_label;
EXTERNAL Widget   mc_hs_label;

/* ADSC_4SLIT */

EXTERNAL Widget   mc_guard_aperature_label;
EXTERNAL Widget   mc_guard_vs_radioBox;
EXTERNAL Widget   mc_guard_hs_radioBox;
EXTERNAL Widget   mc_guard_vs_drive_pushButton;
EXTERNAL Widget   mc_guard_hs_drive_pushButton;
EXTERNAL Widget   mc_guard_hs_apply_pushButton;
EXTERNAL Widget   mc_guard_vs_apply_pushButton;
EXTERNAL Widget   mc_guard_vs_zero_pushButton;
EXTERNAL Widget   mc_guard_hs_zero_pushButton;
EXTERNAL Widget   mc_guard_vs_label;
EXTERNAL Widget   mc_guard_hs_label;
EXTERNAL Widget   mc_guard_vs_textField;
EXTERNAL Widget   mc_guard_hs_textField;

/*
 * End Global Widget Declarations.
 */
#endif