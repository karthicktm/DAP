# Generate Music

> Generate music with or without lyrics using AI models.

## OpenAPI

````yaml suno-api/suno-api.json post /api/v1/generate
paths:
  path: /api/v1/generate
  method: post
  servers:
    - url: https://api.kie.ai
      description: API Server
  request:
    security:
      - title: BearerAuth
        parameters:
          query: {}
          header:
            Authorization:
              type: http
              scheme: bearer
              description: >-
                All APIs require authentication via Bearer Token.


                Get API Key:

                1. Visit [API Key Management Page](https://kie.ai/api-key) to
                get your API Key


                Usage:

                Add to request header:

                Authorization: Bearer YOUR_API_KEY


                Note:

                - Keep your API Key secure and do not share it with others

                - If you suspect your API Key has been compromised, reset it
                immediately in the management page
          cookie: {}
    parameters:
      path: {}
      query: {}
      header: {}
      cookie: {}
    body:
      application/json:
        schemaArray:
          - type: object
            properties:
              prompt:
                allOf:
                  - type: string
                    description: >-
                      A description of the desired audio content.  

                      - In Custom Mode (`customMode: true`): Required if
                      `instrumental` is `false`. The prompt will be strictly
                      used as the lyrics and sung in the generated track.
                      Character limits by model:  
                        - **V3_5 & V4**: Maximum 3000 characters  
                        - **V4_5 & V4_5PLUS**: Maximum 5000 characters  
                        - **V5**: Maximum 5000 characters  
                        Example: "A calm and relaxing piano track with soft melodies"  
                      - In Non-custom Mode (`customMode: false`): Always
                      required. The prompt serves as the core idea, and lyrics
                      will be automatically generated based on it (not strictly
                      matching the input). Maximum 500 characters.  
                        Example: "A short relaxing piano tune"
                    example: A calm and relaxing piano track with soft melodies
              style:
                allOf:
                  - type: string
                    description: >-
                      Music style specification for the generated audio.  

                      - Required in Custom Mode (`customMode: true`). Defines
                      the genre, mood, or artistic direction.  

                      - Character limits by model:  
                        - **V3_5 & V4**: Maximum 200 characters  
                        - **V4_5 & V4_5PLUS**: Maximum 1000 characters  
                        - **V5**: Maximum 1000 characters  
                      - Common examples: Jazz, Classical, Electronic, Pop, Rock,
                      Hip-hop, etc.
                    example: Classical
              title:
                allOf:
                  - type: string
                    description: |-
                      Title for the generated music track.  
                      - Required in Custom Mode (`customMode: true`).  
                      - Max length: 80 characters.  
                      - Will be displayed in player interfaces and filenames.
                    example: Peaceful Piano Meditation
              customMode:
                allOf:
                  - type: boolean
                    description: >-
                      Determines if advanced parameter customization is
                      enabled.  

                      - If `true`: Allows detailed control with specific
                      requirements for `style` and `title` fields.  

                      - If `false`: Simplified mode where only `prompt` is
                      required and other parameters are ignored.
                    example: true
              instrumental:
                allOf:
                  - type: boolean
                    description: >-
                      Determines if the audio should be instrumental (no
                      lyrics).  

                      - In Custom Mode (`customMode: true`):  
                        - If `true`: Only `style` and `title` are required.  
                        - If `false`: `style`, `title`, and `prompt` are required (with prompt used as the exact lyrics).  
                      - In Non-custom Mode (`customMode: false`): No impact on
                      required fields (prompt only).
                    example: true
              model:
                allOf:
                  - type: string
                    description: |-
                      The AI model version to use for generation.  
                      - Required for all requests.  
                      - Available options:  
                        - **`V5`**: Superior musical expression, faster generation.  
                        - **`V4_5PLUS`**: V4.5+ is richer sound, new waysto create, max 8 min.  
                        - **`V4_5`**: V4.5 is smarter prompts, fastergenerations, max 8 min.  
                        - **`V4`**: V4 is improved vocal quality,max 4 min.  
                        - **`V3_5`**: V3.5 is better song structure,max 4 min.
                    enum:
                      - V3_5
                      - V4
                      - V4_5
                      - V4_5PLUS
                      - V5
                    example: V3_5
              callBackUrl:
                allOf:
                  - type: string
                    format: uri
                    description: >-
                      The URL to receive music generation task completion
                      updates. Required for all music generation requests.


                      - System will POST task status and results to this URL
                      when generation completes

                      - Callback process has three stages: `text` (text
                      generation), `first` (first track complete), `complete`
                      (all tracks complete)

                      - Note: Some cases may skip `text` and `first` stages and
                      return `complete` directly

                      - Your callback endpoint should accept POST requests with
                      JSON payload containing task results and audio URLs

                      - For detailed callback format and implementation guide,
                      see [Music Generation
                      Callbacks](./generate-music-callbacks)

                      - Alternatively, use the Get Music Details endpoint to
                      poll task status
                    example: https://api.example.com/callback
              negativeTags:
                allOf:
                  - type: string
                    description: >-
                      Music styles or traits to exclude from the generated
                      audio. Optional. Use to avoid specific styles.
                    example: Heavy Metal, Upbeat Drums
              vocalGender:
                allOf:
                  - type: string
                    description: >-
                      Vocal gender preference for the singing voice. Optional.
                      Use 'm' for male and 'f' for female. Note: This parameter
                      is only effective when customMode is true. Based on
                      practice, this parameter can only increase the probability
                      but cannot guarantee adherence to male/female voice
                      instructions.
                    enum:
                      - m
                      - f
                    example: m
              styleWeight:
                allOf:
                  - type: number
                    description: >-
                      Strength of adherence to the specified style. Optional.
                      Range 0–1, up to 2 decimal places.
                    minimum: 0
                    maximum: 1
                    multipleOf: 0.01
                    example: 0.65
              weirdnessConstraint:
                allOf:
                  - type: number
                    description: >-
                      Controls experimental/creative deviation. Optional. Range
                      0–1, up to 2 decimal places.
                    minimum: 0
                    maximum: 1
                    multipleOf: 0.01
                    example: 0.65
              audioWeight:
                allOf:
                  - type: number
                    description: >-
                      Balance weight for audio features vs. other factors.
                      Optional. Range 0–1, up to 2 decimal places.
                    minimum: 0
                    maximum: 1
                    multipleOf: 0.01
                    example: 0.65
              personaId:
                allOf:
                  - type: string
                    description: >-
                      Only available when Custom Mode (`customMode: true`) is
                      enabled. Persona ID to apply to the generated music.
                      Optional. Use this to apply a specific persona style to
                      your music generation. 


                      To generate a persona ID, use the [Generate
                      Persona](generate-persona) endpoint to create a
                      personalized music Persona based on generated music.
                    example: persona_123
            required: true
            requiredProperties:
              - customMode
              - instrumental
              - callBackUrl
              - model
              - prompt
        examples:
          example:
            value:
              prompt: A calm and relaxing piano track with soft melodies
              style: Classical
              title: Peaceful Piano Meditation
              customMode: true
              instrumental: true
              model: V3_5
              callBackUrl: https://api.example.com/callback
              negativeTags: Heavy Metal, Upbeat Drums
              vocalGender: m
              styleWeight: 0.65
              weirdnessConstraint: 0.65
              audioWeight: 0.65
              personaId: persona_123
  response:
    '200':
      application/json:
        schemaArray:
          - type: object
            properties:
              code:
                allOf:
                  - type: integer
                    enum:
                      - 200
                      - 401
                      - 402
                      - 404
                      - 409
                      - 422
                      - 429
                      - 451
                      - 455
                      - 500
                    description: >-
                      Response Status Codes


                      - **200**: Success - Request has been processed
                      successfully  

                      - **401**: Unauthorized - Authentication credentials are
                      missing or invalid  

                      - **402**: Insufficient Credits - Account does not have
                      enough credits to perform the operation  

                      - **404**: Not Found - The requested resource or endpoint
                      does not exist  

                      - **409**: Conflict - WAV record already exists  

                      - **422**: Validation Error - The request parameters
                      failed validation checks  

                      - **429**: Rate Limited - Request limit has been exceeded
                      for this resource  

                      - **451**: Unauthorized - Failed to fetch the image.
                      Kindly verify any access limits set by you or your service
                      provider  

                      - **455**: Service Unavailable - System is currently
                      undergoing maintenance  

                      - **500**: Server Error - An unexpected error occurred
                      while processing the request
              msg:
                allOf:
                  - type: string
                    description: Error message when code != 200
                    example: success
              data:
                allOf:
                  - type: object
                    properties:
                      taskId:
                        type: string
                        description: >-
                          Task ID for tracking task status. Use this ID with the
                          "Get Music Details" endpoint to query task details and
                          results.
                        example: 5c79****be8e
        examples:
          example:
            value:
              code: 200
              msg: success
              data:
                taskId: 5c79****be8e
        description: Request successful
    '500':
      _mintlify/placeholder:
        schemaArray:
          - type: any
            description: Server Error
        examples: {}
        description: Server Error
  deprecated: false
  type: path
components:
  schemas: {}

````

# Music Generation Callbacks

> System will call this callback when audio generation is complete.

When you submit a music generation task to the Suno API, you can use the `callBackUrl` parameter to set a callback URL. The system will automatically push the results to your specified address when the task is completed.

## Callback Mechanism Overview

<Info>
  The callback mechanism eliminates the need to poll the API for task status. The system will proactively push task completion results to your server.
</Info>

### Callback Timing

The system will send callback notifications in the following situations:

* Music generation task completed successfully
* Music generation task failed
* Errors occurred during task processing

### Callback Method

* **HTTP Method**: POST
* **Content Type**: application/json
* **Timeout Setting**: 15 seconds

## Callback Request Format

When the task is completed, the system will send a POST request to your `callBackUrl` in the following format:

<CodeGroup>
  ```json Success Callback theme={null}
  {
    "code": 200,
    "msg": "All generated successfully.",
    "data": {
      "callbackType": "complete",
      "task_id": "2fac****9f72",
      "data": [
        {
          "id": "e231****-****-****-****-****8cadc7dc",
          "audio_url": "https://example.cn/****.mp3",
          "stream_audio_url": "https://example.cn/****",
          "image_url": "https://example.cn/****.jpeg",
          "prompt": "[Verse] Night city lights shining bright",
          "model_name": "chirp-v3-5",
          "title": "Iron Man",
          "tags": "electrifying, rock",
          "createTime": "2025-01-01 00:00:00",
          "duration": 198.44
        },
        {
          "id": "e231****-****-****-****-****8cadc7dc",
          "audio_url": "https://example.cn/****.mp3",
          "stream_audio_url": "https://example.cn/****",
          "image_url": "https://example.cn/****.jpeg",
          "prompt": "[Verse] Night city lights shining bright",
          "model_name": "chirp-v3-5",
          "title": "Iron Man",
          "tags": "electrifying, rock",
          "createTime": "2025-01-01 00:00:00",
          "duration": 228.28
        }
      ]
    }
  }
  ```

  ```json Failure Callback theme={null}
  {
    "code": 501,
    "msg": "Audio generation failed",
    "data": {
      "callbackType": "error",
      "task_id": "2fac****9f72",
      "data": null
    }
  }
  ```
</CodeGroup>

## Status Code Description

<ParamField path="code" type="integer" required>
  Callback status code indicating task processing result:

  | Status Code | Description                                                                                                    |
  | ----------- | -------------------------------------------------------------------------------------------------------------- |
  | 200         | Success - Request has been processed successfully                                                              |
  | 400         | Validation Error - Lyrics contained copyrighted material                                                       |
  | 408         | Rate Limited - Timeout                                                                                         |
  | 413         | Conflict - Uploaded audio matches existing work of art                                                         |
  | 500         | Server Error - An unexpected error occurred while processing the request                                       |
  | 501         | Audio generation failed                                                                                        |
  | 531         | Server Error - Sorry, the generation failed due to an issue. Your credits have been refunded. Please try again |
</ParamField>

<ParamField path="msg" type="string" required>
  Status message providing detailed status description
</ParamField>

<ParamField path="data.callbackType" type="string" required>
  Callback type:

  * **text** - Text generation complete
  * **first** - First track complete
  * **complete** - All tracks complete
  * **error** - Generation failed
</ParamField>

<ParamField path="data.task_id" type="string" required>
  Task ID, consistent with the task\_id returned when you submitted the task
</ParamField>

<ParamField path="data.data" type="array">
  Generated audio data array, returned on success
</ParamField>

<ParamField path="data.data[].id" type="string">
  Audio unique identifier (audioId)
</ParamField>

<ParamField path="data.data[].audio_url" type="string">
  Audio file URL
</ParamField>

<ParamField path="data.data[].stream_audio_url" type="string">
  Streaming audio URL
</ParamField>

<ParamField path="data.data[].image_url" type="string">
  Cover image URL
</ParamField>

<ParamField path="data.data[].prompt" type="string">
  Generation prompt/lyrics
</ParamField>

<ParamField path="data.data[].model_name" type="string">
  Model name used
</ParamField>

<ParamField path="data.data[].title" type="string">
  Music title
</ParamField>

<ParamField path="data.data[].tags" type="string">
  Music tags
</ParamField>

<ParamField path="data.data[].createTime" type="string">
  Creation time
</ParamField>

<ParamField path="data.data[].duration" type="number">
  Audio duration (seconds)
</ParamField>

## Callback Reception Examples

Here are example codes for receiving callbacks in popular programming languages:

<Tabs>
  <Tab title="Node.js">
    ```javascript  theme={null}
    const express = require('express');
    const app = express();

    app.use(express.json());

    app.post('/suno-callback', (req, res) => {
      const { code, msg, data } = req.body;
      
      console.log('Received callback:', {
        taskId: data.task_id,
        status: code,
        message: msg,
        callbackType: data.callbackType
      });
      
      if (code === 200) {
        // Task completed successfully
        if (data.callbackType === 'complete') {
          console.log('Music generation completed:', data.data);
          
          // Process generated music data
          data.data.forEach(audio => {
            console.log(`Audio ID: ${audio.id}`);
            console.log(`Audio URL: ${audio.audio_url}`);
            console.log(`Title: ${audio.title}`);
            console.log(`Duration: ${audio.duration} seconds`);
          });
          
        } else if (data.callbackType === 'first') {
          console.log('First track completed');
          
        } else if (data.callbackType === 'text') {
          console.log('Text generation completed');
        }
        
      } else {
        // Task failed
        console.log('Task failed:', msg);
        
        // Handle failure cases...
      }
      
      // Return 200 status code to confirm callback received
      res.status(200).json({ status: 'received' });
    });

    app.listen(3000, () => {
      console.log('Callback server running on port 3000');
    });
    ```
  </Tab>

  <Tab title="Python">
    ```python  theme={null}
    from flask import Flask, request, jsonify
    import json

    app = Flask(__name__)

    @app.route('/suno-callback', methods=['POST'])
    def handle_callback():
        data = request.json
        
        code = data.get('code')
        msg = data.get('msg')
        callback_data = data.get('data', {})
        task_id = callback_data.get('task_id')
        callback_type = callback_data.get('callbackType')
        
        print(f"Received callback: {task_id}, status: {code}, type: {callback_type}, message: {msg}")
        
        if code == 200:
            # Task completed successfully
            if callback_type == 'complete':
                audio_list = callback_data.get('data', [])
                print(f"Music generation completed, generated {len(audio_list)} tracks")
                
                for audio in audio_list:
                    print(f"Audio ID: {audio['id']}")
                    print(f"Audio URL: {audio['audio_url']}")
                    print(f"Title: {audio['title']}")
                    print(f"Duration: {audio['duration']} seconds")
                    
            elif callback_type == 'first':
                print("First track completed")
                
            elif callback_type == 'text':
                print("Text generation completed")
                
        else:
            # Task failed
            print(f"Task failed: {msg}")
            
            # Handle failure cases...
        
        # Return 200 status code to confirm callback received
        return jsonify({'status': 'received'}), 200

    if __name__ == '__main__':
        app.run(host='0.0.0.0', port=3000)
    ```
  </Tab>

  <Tab title="PHP">
    ```php  theme={null}
    <?php
    header('Content-Type: application/json');

    // Get POST data
    $input = file_get_contents('php://input');
    $data = json_decode($input, true);

    $code = $data['code'] ?? null;
    $msg = $data['msg'] ?? '';
    $callbackData = $data['data'] ?? [];
    $taskId = $callbackData['task_id'] ?? '';
    $callbackType = $callbackData['callbackType'] ?? '';

    error_log("Received callback: $taskId, status: $code, type: $callbackType, message: $msg");

    if ($code === 200) {
        // Task completed successfully
        if ($callbackType === 'complete') {
            $audioList = $callbackData['data'] ?? [];
            error_log("Music generation completed, generated " . count($audioList) . " tracks");
            
            foreach ($audioList as $audio) {
                error_log("Audio ID: " . $audio['id']);
                error_log("Audio URL: " . $audio['audio_url']);
                error_log("Title: " . $audio['title']);
                error_log("Duration: " . $audio['duration'] . " seconds");
            }
            
        } elseif ($callbackType === 'first') {
            error_log("First track completed");
            
        } elseif ($callbackType === 'text') {
            error_log("Text generation completed");
        }
        
    } else {
        // Task failed
        error_log("Task failed: $msg");
        
        // Handle failure cases...
    }

    // Return 200 status code to confirm callback received
    http_response_code(200);
    echo json_encode(['status' => 'received']);
    ?>
    ```
  </Tab>
</Tabs>

## Best Practices

<Tip>
  ### Callback URL Configuration Recommendations

  1. **Use HTTPS**: Ensure your callback URL uses HTTPS protocol for secure data transmission
  2. **Verify Source**: Verify the legitimacy of the request source in callback processing
  3. **Idempotent Processing**: The same task\_id may receive multiple callbacks, ensure processing logic is idempotent
  4. **Quick Response**: Callback processing should return a 200 status code as quickly as possible to avoid timeout
  5. **Asynchronous Processing**: Complex business logic should be processed asynchronously to avoid blocking callback response
  6. **Stage Tracking**: Differentiate between different generation stages based on callbackType and arrange business logic appropriately
</Tip>

<Warning>
  ### Important Reminders

  * Callback URL must be a publicly accessible address
  * Server must respond within 15 seconds, otherwise it will be considered a timeout
  * If 3 consecutive retries fail, the system will stop sending callbacks
  * Please ensure the stability of callback processing logic to avoid callback failures due to exceptions
  * Pay attention to handling different callbackType callbacks, especially the complete type for final results
</Warning>

## Troubleshooting

If you do not receive callback notifications, please check the following:

<AccordionGroup>
  <Accordion title="Network Connection Issues">
    * Confirm that the callback URL is accessible from the public network
    * Check firewall settings to ensure inbound requests are not blocked
    * Verify that domain name resolution is correct
  </Accordion>

  <Accordion title="Server Response Issues">
    * Ensure the server returns HTTP 200 status code within 15 seconds
    * Check server logs for error messages
    * Verify that the interface path and HTTP method are correct
  </Accordion>

  <Accordion title="Content Format Issues">
    * Confirm that the received POST request body is in JSON format
    * Check that Content-Type is application/json
    * Verify that JSON parsing is correct
  </Accordion>

  <Accordion title="Callback Type Processing">
    * Confirm proper handling of different callbackTypes
    * Check if processing of complete type final results is missed
    * Verify that audio data parsing is correct
  </Accordion>
</AccordionGroup>

## Alternative Solution

If you cannot use the callback mechanism, you can also use polling:

<Card title="Poll Query Results" icon="radar" href="/suno-api/get-music-details">
  Use the get music details endpoint to regularly query task status. We recommend querying every 30 seconds.
</Card>