#import <mach-o/dyld.h>
#import <pthread/pthread.h>

#define MILLISECOND_BIAS 1000

uint64_t getASLRSlide(){
	return _dyld_get_image_vmaddr_slide(0);
}

void *modifyScore(void *arg0){
	while(true){
		// __symbolstub1:0000000100260398                 STR             X19, [X0,#0x100638240@PAGEOFF]
		void *CScoreManager = *(void **)(getASLRSlide() + 0x100638240);
		
		// turns out CScoreManager isn't the class that holds our score
		// so I had to do a bit of exploring and analysis to find out where it is kept
		if(CScoreManager){
			void *unkptr0 = *(void **)((uint64_t)CScoreManager + 0x70);
			
			if(unkptr0){
				void *unkptr1 = *(void **)((uint64_t)unkptr0 + 0x8);
				
				if(unkptr1){
					// increase our score by 1 every 25 milliseconds
					(*(int *)((uint64_t)unkptr1 + 0x24))++;
				}
			}
		}
		
		usleep(25 * MILLISECOND_BIAS);
	}
	
	return NULL;
}

void *modifyWave(void *arg0){
	// we don't want to keep modifying our wave, only modify it when we're finished with a wave
	int lastWave = 0;
	
	while(true){
		// __symbolstub1:000000010028BBEC                 STR             X19, [X0,#0x1006371F8@PAGEOFF]
		void *CWaveManager = *(void **)(getASLRSlide() + 0x1006371f8);
		
		if(CWaveManager){
			// we could make this an int pointer, but sizeof(int *) == 8 and that causes problems in this particular situation because of overlapping memory
			int currentWave = *(int *)((uint64_t)CWaveManager + 0xd8);
			
			if(currentWave != lastWave){
				// currentWave's value has already been updated
				// if we multiply that by two, we'll get the wrong wave value
				// using lastWave fixes this because it hasn't been updated
				// sometimes lastWave is 0, so we need to handle that
				// will double the wave you're on every time you finish a wave
				*(int *)((uint64_t)CWaveManager + 0xd8) = ((lastWave == 0 ? 1 : lastWave) * 2);
				
				// we only want to modify the wave once
				// there is absolutely no way a wave will last only five seconds
				sleep(5);
			}
			
			// be sure to update lastWave correctly
			lastWave = *(int *)((uint64_t)CWaveManager + 0xd8);
		}
		
		usleep(25 * MILLISECOND_BIAS);
	}
	
	return NULL;
}

void *pickupHacks(void *arg0){
	while(true){
		// __symbolstub1:000000010022DB70                 STR             X19, [X0,#0x100637210@PAGEOFF]
		void *CPickupManager = *(void **)(getASLRSlide() + 0x100637210);
		
		if(CPickupManager){
			// the game uses however many points you've earned since last pickup to decide whether or not to spawn a pickup
			// setting this to a ridiculously large value tricks the game into thinking it's been a long time since the last pickup spawn
			*(int *)((uint64_t)CPickupManager + 0xd0) = 999999999;
			
			// however, there's a limit to the number of pickups that spawn each round so we need to patch that
			// this is guaranteed not to be NULL - you can tell from the assembly
			void *maxPickupLimitDvar = *(void **)((uint64_t)CPickupManager + 0x150);
			*(int *)((uint64_t)maxPickupLimitDvar + 0x20) = 999999999;
		}
		
		usleep(25 * MILLISECOND_BIAS);
	}
		
	return NULL;
}

%hook s3eAppDelegate

- (void)applicationDidBecomeActive:(id)arg0 {
	dispatch_after(dispatch_time(DISPATCH_TIME_NOW, 5 * NSEC_PER_SEC), dispatch_get_main_queue(), ^ {
		pthread_t scoreThread;
		pthread_create(&scoreThread, NULL, modifyScore, NULL);

		pthread_t waveThread;
		pthread_create(&waveThread, NULL, modifyWave, NULL);

		pthread_t pickupThread;
		pthread_create(&pickupThread, NULL, pickupHacks, NULL);
	});
	
	%orig;
}
