// --------------------------------------------------------------------
// Copyright (c) 2010 by Terasic Technologies Inc. 
// --------------------------------------------------------------------
//
// Permission:
//
//   Terasic grants permission to use and modify this code for use
//   in synthesis for all Terasic Development Boards and Altera Development 
//   Kits made by Terasic.  Other use of this code, including the selling 
//   ,duplication, or modification of any portion is strictly prohibited.
//
// Disclaimer:
//
//   This VHDL/Verilog or C/C++ source code is intended as a design reference
//   which illustrates how these types of functions can be implemented.
//   It is the user's responsibility to verify their design for
//   consistency and functionality through the use of formal
//   verification methods.  Terasic provides no warranty regarding the use 
//   or functionality of this code.
//
// --------------------------------------------------------------------
//           
//                     Terasic Technologies Inc
//                     356 Fu-Shin E. Rd Sec. 1. JhuBei City,
//                     HsinChu County, Taiwan
//                     302
//
//                     web: http://www.terasic.com/
//                     email: support@terasic.com
//
// --------------------------------------------------------------------
// Last built by: Quartus 9.1 SP2 build 350
// Supported File Format: FAT16 & FAT 32
// Supported SDCARD: SD, HCSD

#include <string.h>
#include <stdio.h>
#include "terasic_includes.h"
#include "fat_file.h"
#include "fat.h"
#include "sd_controller.h"
#include "system.h"
#include "altera_avalon_pio_regs.h"
#include "midi.h"

typedef struct {
  unsigned int image_offset;
  unsigned char type;
  int image_length;
  unsigned int image_crc;
  int progress; //download progress
  char hw_filename[80];
  char sw_filename[80];
  unsigned int directory;
  char app_name[80];
} app_info;

#define AS_MAX_SDCARD_APPS              40
#define p2_size							288

typedef struct {
  app_info apps[AS_MAX_SDCARD_APPS];
  int num_apps;
  int target_app;
  int action;
} app_list_struct;

//------------------ SD Card Dir  ---------------------------
bool sd_card_mount_init();
int AsFindAppsOnSD( app_list_struct* sd_app_list );


app_list_struct* app_list;

bool sd_card_mount_init()
{
    int volumes_mounted = 0;
    int nTryTime = 0;

    for(nTryTime = 0; nTryTime <3 ; nTryTime ++)
    {
        //Init sd card
        SD_CONTROLLER_INSTANCE( SD_CONTROLLER_0, sd_controller_0 );
        SD_CONTROLLER_INIT( SD_CONTROLLER_0, sd_controller_0 );
        ////set spi clock divider coeff.
        sd_set_clock_to_max( 80000000 );
        usleep (1000);
        ////mount fat file system.
        volumes_mounted = sd_fat_mount_all();

        if( volumes_mounted <= 0 && nTryTime == 2)
        {
            return FALSE;
        }
        else if(volumes_mounted > 0)
        {
            break;
        }
    }
    return TRUE;
}


/*****************************************************************************
*  Function: AsFindAppsOnSD
*
*  Purpose: Looks through the directory of the SD Card where the loadable
*           application are, and fills out a list of all the valid-looking
*           applications it finds.
*
*  Possible enhancements: Remove the error message displaying from here,
*                         and just pass back an error code.
*
*  Returns: 0     - Success
*           non-0 - Failure
****************************************************************************/


int AsFindAppsOnSD( app_list_struct* sd_app_list )
{
  bool bFind = FALSE;
  bFind = sd_card_mount_init();
  if(!bFind)
  {
       printf("cann't find sdcard \n");
//      lcd_display( "\rcann't find sdcard\n\n" );

       return -1;
  }
   char buf[800] = {0};
//   int fileNum = sd_list("/sounds/",buf);
   int fileNum = sd_list("/sounds/",buf);
   if(fileNum <= 0)
   {
       printf("cann't find file in specified directory\n");
//       lcd_display( "\rcann't find file in specified directory\n\n" );
       return -1;
   }

   sd_app_list->num_apps = 0;

   int i=0;
   int start = -1;
   int end   = -1;

   char name[80] = {0};
   for(i=0;i<800;i++)
   {
       if(buf[i] !='\0' && start == -1) //start Dir
       {
           start = i;
           end = -1;
       }
       else if(buf[i] == '\0' && end == -1)//end Dir
       {
           end = i;
           memcpy(name,buf+start,end-start+1);

           if(name[0] != '.') //
           {
               strcpy( sd_app_list->apps[sd_app_list->num_apps].app_name, name );
               strcpy( sd_app_list->apps[sd_app_list->num_apps].sw_filename, "");
               strcpy( sd_app_list->apps[sd_app_list->num_apps].hw_filename, "");
               //strcpy(app_list[iIndex].Dir , name);

               //search hardware file and software file
               char tmpBuf[100] = {0};
               char path[100] = {0};
               int  tmpStart = -1;
               int  tmpEnd  = -1;
               char tmpName[80] = {0};

               sprintf(path,"/sounds/%s/",sd_app_list->apps[sd_app_list->num_apps].app_name);
               sd_list(path,tmpBuf);

               int j=0;
               for(j=0;j<100;j++)
               {
                   if(tmpBuf[j] !='\0' && tmpStart == -1)  //start file
                   {
                       tmpStart = j;
                       tmpEnd = -1;
                   }
                   else if(tmpBuf[j] == '\0' && tmpEnd == -1)//end file
                   {
                       tmpEnd = j;
                       memcpy(tmpName,tmpBuf+tmpStart,tmpEnd-tmpStart+1);
                       if(tmpName[0] != '.')
                       {
                           char *pdest = NULL;
                           pdest = strstr(tmpName,"p");
                           if(pdest != NULL)
                           {
                               strcpy( sd_app_list->apps[sd_app_list->num_apps].sw_filename, tmpName );
                           }

                           pdest = strstr(tmpName,"p2_");
                           if(pdest != NULL)
                           {
                               strcpy( sd_app_list->apps[sd_app_list->num_apps].hw_filename, tmpName );
                           }
                       }
                       tmpStart = -1;
                   }
               }
               //iIndex ++;
               sd_app_list->num_apps++;
           }
           start = -1;
       }
   }
   for(i=0;i<sd_app_list->num_apps;i++)
   {
	   printf("file %d = %s\n\r",i,sd_app_list->apps[i].app_name);
   }
   return 0;
}


// ----------------------- Sd card dir end ------------------------------------------------

static void handle_save_interrupts(void* context)
{
//	int ret_code;
	/* Cast context to edge_capture's type. It is important that this
	be declared volatile to avoid unwanted compiler optimization. */
	volatile int* edge_capture_ptr = (volatile int*) context;
	/*
	* Read the edge capture register on the button PIO.
	* Store value.
	*/
	*edge_capture_ptr =
	IORD_ALTERA_AVALON_PIO_EDGE_CAP(N_IRQ_BASE);
	// send ok back to touch by writing pulse on bit 8
//	IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, 0x80);
//	IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, 0x00);
	/* Write to the edge capture register to reset it. */
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(N_IRQ_BASE, 3);
	/* Read the PIO to delay ISR exit. This is done to prevent a
	spurious interrupt in systems with high processor -> pio
	latency and fast interrupts. */
	IORD_ALTERA_AVALON_PIO_EDGE_CAP(N_IRQ_BASE);
}
	volatile int edge_capture;

static void init_save_pio()
{
	/* Recast the edge_capture pointer to match the
	alt_irq_register() function prototype. */
	void* edge_capture_ptr = (void*) &edge_capture;
	/* Enable all 4 button interrupts. */
	IOWR_ALTERA_AVALON_PIO_IRQ_MASK(N_IRQ_BASE, 0x3);
	/* Reset the edge capture register. */
	IOWR_ALTERA_AVALON_PIO_EDGE_CAP(N_IRQ_BASE, 0x3);
	/* Register the ISR. */
	alt_ic_isr_register(N_IRQ_IRQ_INTERRUPT_CONTROLLER_ID,
		N_IRQ_IRQ,
		handle_save_interrupts,
		edge_capture_ptr, 0x0);
}


int LoadDataFromSD( char *file_name )
{
//    char buf[800] = {0};
//    sd_list("/",buf);
//    int fd,sfd =0;
    int fd =0;
//    int file_length=0;
//    int remaining_length = 0;  //remain file size

//    char name[80] = {0};
       char tmpBuf[p2_size] = {0};
        int n,i;
        char tmpName[80] = {0};
        char prg_num;
        prg_num = IORD_ALTERA_AVALON_PIO_DATA(N_SYNTH_SOUND_NUM_BASE);
        sprintf(tmpName,"/sounds/p2_%d%s",prg_num,file_name);
 					printf("will open %s\n",tmpName);
					if((fd = sd_open(tmpName,O_RDWR)) == -1){
						printf("cant open file %s !!\n",tmpName);
					}
					else 	printf("file %s opened ok \n",tmpName);
					printf("reading file \n");
					if((n = sd_read(fd,tmpBuf,p2_size)) == -1){
						printf("can't open file %s !!\n",fd);
					}
					else printf("file read OK ... %d \n",n);

					for(i=0; i < p2_size; i++ ){
						IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, i);
						IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_DAT_RDY_BASE, 0x00);
						IOWR_ALTERA_AVALON_PIO_DATA(N_SYNTH_IN_DATA_BASE, tmpBuf[i]);
						IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_DAT_RDY_BASE, 0x03);// 2'b01 = read from synth/save to disk; 2'b11 = write to synth/load from disk
//						printf("data %d %s = %d \n",i,midi_buf2[i],tmpBuf[i]);
					}
					for(i=0; i < p2_size; i++ ){
						printf("data %d %s = %d \n",i,midi_buf2[i],tmpBuf[i]);
					}
					printf("program loaded ...  \n");
					IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_DAT_RDY_BASE, 0x00);
					// send ok back to touch by writing pulse on bit 9
					IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, 0x200);
					IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, 0x000);
					sd_close(fd);
					printf(" %s is loaded \n",tmpName);
//	}
//    start = -1;
    return 0;
}

int SaveDataOnSD( char *file_name )
{
    int volumes_mounted;
    int n = p2_size;
    ////set spi clock divider coeff.
    sd_set_clock_to_max( 80000000 );
    usleep (1000);
    ////mount fat file system.
    volumes_mounted = sd_fat_mount_all();

    if( volumes_mounted <= 0 )
    {
        return -1;
    }
    char chrbuf[p2_size] = {0};
    char f_name[80];
    int sfd =0;
    int prg_num = 0;

    int i=0;
	prg_num = IORD_ALTERA_AVALON_PIO_DATA(N_SYNTH_SOUND_NUM_BASE);
    sprintf(f_name,"/sounds/p2_%d%s",prg_num,file_name);
    if((sfd = sd_creat(f_name,O_RDWR)) == -1){
		printf("cant open save file %s !!\n",f_name);
	}else {
		printf("file %s opened ok \n",f_name);
		for(i=0; i < p2_size; i++ ){
			IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, i);
			IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_DAT_RDY_BASE, 0x00);
			IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_DAT_RDY_BASE, 0x01);// 2'b01 = read from synth/save to disk; 2'b11 = write to synth/load from disk
			chrbuf[i] = IORD_ALTERA_AVALON_PIO_DATA(N_SYNTH_OUT_DATA_BASE);
			printf("data %d %s = %d \n",i,midi_buf2[i],chrbuf[i]);
		}
		IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_DAT_RDY_BASE, 0x00);
		if(sd_write(sfd,chrbuf,n)!=n)
			printf("write error !!\n");
		else {
			printf("file %s written ok \n ",f_name);
		}
		// send ok back to touch by writing pulse on bit 9
		IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, 0x200);
		IOWR_ALTERA_AVALON_PIO_DATA(N_ADR_BASE, 0x000);
		sd_close(sfd);
	}
    return 0;
}


int main()
{
	int ret_code;
    int volumes_mounted;
//	char string[128];
	app_list = malloc( sizeof( app_list_struct ));

//    app_list_struct* sd_app_list;
    printf("========== DE2-115 SDCARD Demo ==========\n");
    init_save_pio();
    printf("Interrupt routine init ok \n");
    alt_ic_irq_enable(N_IRQ_IRQ_INTERRUPT_CONTROLLER_ID,N_IRQ_IRQ);
    printf("Interrupt routine enabled \n");
	ret_code = AsFindAppsOnSD( app_list );
	if( ret_code )
	{
//		sprintf( string, "Error: Could not find any Sound Files on SD Card\nInsert a properly loaded SD Card then reset the board." );
		printf( "Error: Could not find any Sound Files on SD Card\nInsert a properly loaded SD Card then reset the board." );
        return -1;
	}
    ////set spi clock divider coeff.
    sd_set_clock_to_max( 80000000 );
    printf("sleep 1000\n");
    usleep (1000);
    printf("mounting\n");
    ////mount fat file system.
    volumes_mounted = sd_fat_mount_all();

    if( volumes_mounted <= 0 )
    {
        printf("Not mounted \n\r");
    	return -1;
    }
   sd_set_clock_to_max( 80000000 );
    printf("sleep 1000\n");
    usleep (1000);
    printf("mounting\n");
    ////mount fat file system.
    volumes_mounted = sd_fat_mount_all();

    if( volumes_mounted <= 0 )
    {
        printf("Not mounted \n\r");
    	return -1;
    }
   while(1){
        printf("Processing...\r\n");
		printf("edge_capture = %d\n",edge_capture);
    	if(edge_capture == 1)
    	{
    		ret_code = SaveDataOnSD( ".lst" );
    		if( ret_code )
    		{
    			printf("Error: Could not find any SD Card\nInsert a properly loaded SD Card then reset the board.\n" );
    		}
    		else printf("Interrupt %d serviced\n",edge_capture);
    		edge_capture = 0;
    	}
       	if(edge_capture == 2)
       	{
       		printf("please wait while loading \n");
    		ret_code = LoadDataFromSD( ".lst" );
    		if( ret_code )
    		{
    			printf("Error: Could not find any Patches on SD Card\nInsert a properly loaded SD Card then reset the board.\n" );
    		}
    		else printf("Interrupt %d serviced\n",edge_capture);
    		edge_capture = 0;
       	}
            printf("===== Ready =====\r\nPress load or save.\r\n");
            while (edge_capture == 0x00);
    }
  

  return 0;
}
