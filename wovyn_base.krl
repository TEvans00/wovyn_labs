ruleset wovyn_base {
  meta {
    name "Wovyn Base"
    author "Tyla Evans"
    use module com.twilio.sdk alias sdk
      with
        authToken = meta:rulesetConfig{"auth_token"}
        sessionID = meta:rulesetConfig{"session_id"}
  }

  global {
    temperature_threshold = 71
    notification_number = "+13033324277"
  }

  rule process_heartbeat {
    select when wovyn heartbeat
    if event:attrs{"genericThing"} then
      send_directive("heartbeat", {"body": "Temperature reading received"})
    fired {
      raise wovyn event "new_temperature_reading" attributes {
        "temperature" : event:attrs{"genericThing"}{"data"}{"temperature"}[0]{"temperatureF"},
        "timestamp" : event:time
      }
    }
  }

  rule find_high_temps {
    select when wovyn new_temperature_reading
    pre {
      temperature = event:attrs{"temperature"}.klog("temperature:")
    }
    if true then noop()
    always {
      raise wovyn event "threshold_violation"
      attributes event:attrs
      if (temperature > temperature_threshold).klog("above threshold:")
    }
  }

  rule threshold_notification {
    select when wovyn threshold_violation
    pre {
      body = ("Warning: The temperature has reached " + event:attrs{"temperature"} + " degrees, which is above the threshold of " + temperature_threshold + " degrees.").klog("temperature warning message: ")
    }
    if true then sdk:sendMessage(notification_number, "+16066033227", body) setting(response)
  }
}
