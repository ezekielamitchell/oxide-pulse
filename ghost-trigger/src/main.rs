use esp_idf_svc::hal::delay::FreeRtos;

fn main(){
    // link patches to the esp-idf logging system
    esp_idf_svc::sys::link_patches();
    esp_idf_svc::log::EspLogger::initialize_default();

    // this variable represents a sensor state
    // in code - it is permanently false and be force to true via JTAG
    let mut threat_detected = false;
    let mut counter = 0;

    log::info!("System altered!");

    loop{
        // simulate sensor check
        counter += 1;

        // allow the variable to 'live' so optimizer doesn't delete it
        // and returns a place to breakpoint
        core::hint::black_box(&threat_detected);

        if threat_detected{
            log::error!(" !! THREAT DETECTED !! [Cycle: {}]", counter);
            log::warn!("Engaging backup protocols...");

            // reset for next state
            threat_detected = false;
            FreeRtos::delay_ms(2000);
        } else{
            log::info!("System secure. [Cycle: {}]", counter);
        }
        FreeRtos::delay_ms(1000);
    }
}
