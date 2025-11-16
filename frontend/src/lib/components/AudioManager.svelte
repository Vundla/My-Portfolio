// Enterprise Audio Manager - Borrowing Phoenix LiveView patterns
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { writable } from 'svelte/store';
  import type { HubConnection } from '@microsoft/signalr';

  // Enterprise-grade state management (borrowed from C# patterns)
  interface AudioState {
    isRecording: boolean;
    isProcessing: boolean;
    transcript: string;
    audioLevel: number;
    error: string | null;
    deviceId: string | null;
  }

  // Reactive stores (Svelte's strength enhanced with enterprise patterns)
  export const audioState = writable<AudioState>({
    isRecording: false,
    isProcessing: false,
    transcript: '',
    audioLevel: 0,
    error: null,
    deviceId: null
  });

  // Props with enterprise validation
  export let sessionId: string = crypto.randomUUID();
  export let autoStart: boolean = false;
  export let enableSpeechRecognition: boolean = true;
  export let signalRConnection: HubConnection | null = null;

  // Audio processing variables
  let mediaRecorder: MediaRecorder | null = null;
  let audioContext: AudioContext | null = null;
  let analyser: AnalyserNode | null = null;
  let recognition: SpeechRecognition | null = null;
  let stream: MediaStream | null = null;
  let animationFrame: number;

  // Fault-tolerant initialization (borrowing BEAM supervision tree concepts)
  onMount(async () => {
    try {
      await initializeAudioSystem();
      setupSpeechRecognition();
      setupSignalRListeners();
      
      if (autoStart) {
        await startRecording();
      }
    } catch (error) {
      handleError('Audio system initialization failed', error);
    }
  });

  onDestroy(() => {
    cleanup();
  });

  // Enterprise-grade error handling (C# pattern)
  function handleError(message: string, error: any) {
    console.error(message, error);
    audioState.update(state => ({
      ...state,
      error: `${message}: ${error.message}`,
      isRecording: false,
      isProcessing: false
    }));
  }

  // Hot-swappable audio initialization (borrowing Phoenix LiveView hot code reload)
  async function initializeAudioSystem() {
    if (typeof window === 'undefined' || typeof navigator === 'undefined') {
      throw new Error('Audio system requires browser environment');
    }

    // Request microphone access with enterprise-grade constraints
    const constraints = {
      audio: {
        echoCancellation: true,
        noiseSuppression: true,
        autoGainControl: true,
        sampleRate: 44100,
        channelCount: 2
      }
    };

    stream = await navigator.mediaDevices.getUserMedia(constraints);
    
    // Initialize Web Audio API for real-time analysis
    audioContext = new (window.AudioContext || (window as any).webkitAudioContext)();
    const source = audioContext.createMediaStreamSource(stream);
    analyser = audioContext.createAnalyser();
    analyser.fftSize = 256;
    source.connect(analyser);

    // Initialize MediaRecorder for audio capture
    mediaRecorder = new MediaRecorder(stream, {
      mimeType: 'audio/webm;codecs=opus'
    });

    setupMediaRecorderEvents();
    startAudioLevelMonitoring();
  }

  // Speech recognition with fault tolerance
  function setupSpeechRecognition() {
    if (!enableSpeechRecognition || typeof window === 'undefined') return;

    const SpeechRecognition = (window as any).SpeechRecognition || 
                             (window as any).webkitSpeechRecognition;
    
    if (!SpeechRecognition) {
      console.warn('Speech recognition not supported');
      return;
    }

    recognition = new SpeechRecognition();
    recognition.continuous = true;
    recognition.interimResults = true;
    recognition.lang = 'en-US';

    recognition.onresult = (event: SpeechRecognitionEvent) => {
      let transcript = '';
      for (let i = event.resultIndex; i < event.results.length; i++) {
        transcript += event.results[i][0].transcript;
      }
      
      audioState.update(state => ({
        ...state,
        transcript
      }));

      // Send to backend via SignalR (real-time cross-referencing)
      signalRConnection?.invoke('SendMessage', sessionId, {
        type: 'transcript',
        content: transcript,
        timestamp: new Date().toISOString()
      });
    };

    recognition.onerror = (event) => {
      handleError('Speech recognition error', event);
    };
  }

  // Real-time audio level monitoring (borrowed from advanced audio frameworks)
  function startAudioLevelMonitoring() {
    if (!analyser) return;

    const bufferLength = analyser.frequencyBinCount;
    const dataArray = new Uint8Array(bufferLength);

    function updateAudioLevel() {
      if (!analyser) return;

      analyser.getByteFrequencyData(dataArray);
      const level = dataArray.reduce((sum, value) => sum + value, 0) / bufferLength / 255;
      
      audioState.update(state => ({
        ...state,
        audioLevel: level
      }));

      animationFrame = requestAnimationFrame(updateAudioLevel);
    }

    updateAudioLevel();
  }

  // MediaRecorder event handling with enterprise patterns
  function setupMediaRecorderEvents() {
    if (!mediaRecorder) return;

    const audioChunks: Blob[] = [];

    mediaRecorder.ondataavailable = (event) => {
      audioChunks.push(event.data);
    };

    mediaRecorder.onstop = async () => {
      try {
        const audioBlob = new Blob(audioChunks, { type: 'audio/webm' });
        await processAudioData(audioBlob);
      } catch (error) {
        handleError('Audio processing failed', error);
      } finally {
        audioState.update(state => ({
          ...state,
          isProcessing: false
        }));
      }
    };

    mediaRecorder.onerror = (event) => {
      handleError('MediaRecorder error', event);
    };
  }

  // Enterprise audio processing with backend integration
  async function processAudioData(audioBlob: Blob) {
    audioState.update(state => ({ ...state, isProcessing: true }));

    try {
      const formData = new FormData();
      formData.append('audio', audioBlob);
      formData.append('sessionId', sessionId);

      const response = await fetch('/api/audio/process', {
        method: 'POST',
        body: formData
      });

      if (!response.ok) {
        throw new Error(`HTTP error! status: ${response.status}`);
      }

      const result = await response.json();
      
      // Broadcast via SignalR for real-time updates
      signalRConnection?.invoke('SendAudioData', sessionId, result);
      
    } catch (error) {
      handleError('Backend audio processing failed', error);
    }
  }

  // SignalR real-time listeners (Phoenix LiveView pattern)
  function setupSignalRListeners() {
    if (!signalRConnection) return;

    signalRConnection.on('AudioProcessed', (data) => {
      console.log('Audio processed:', data);
      // Handle processed audio results
    });

    signalRConnection.on('TranscriptionComplete', (data) => {
      audioState.update(state => ({
        ...state,
        transcript: data.transcript
      }));
    });
  }

  // Public API methods (C# style interface)
  export async function startRecording() {
    try {
      if (!mediaRecorder || mediaRecorder.state === 'recording') return;

      audioState.update(state => ({ 
        ...state, 
        isRecording: true, 
        error: null 
      }));

      mediaRecorder.start(1000); // Capture audio in 1-second chunks
      recognition?.start();

    } catch (error) {
      handleError('Failed to start recording', error);
    }
  }

  export function stopRecording() {
    try {
      if (mediaRecorder?.state === 'recording') {
        mediaRecorder.stop();
      }
      
      recognition?.stop();
      
      audioState.update(state => ({ 
        ...state, 
        isRecording: false 
      }));

    } catch (error) {
      handleError('Failed to stop recording', error);
    }
  }

  export function toggleRecording() {
    const { isRecording } = $audioState;
    if (isRecording) {
      stopRecording();
    } else {
      startRecording();
    }
  }

  // Cleanup (BEAM supervision pattern)
  function cleanup() {
    if (animationFrame) {
      cancelAnimationFrame(animationFrame);
    }
    
    recognition?.stop();
    recognition = null;
    
    mediaRecorder?.stop();
    mediaRecorder = null;
    
    stream?.getTracks().forEach(track => track.stop());
    stream = null;
    
    audioContext?.close();
    audioContext = null;
  }

  // Export state for external access
  export { audioState as state };
</script>

<!-- Audio Manager doesn't render UI directly - it's a service component -->
<div class="audio-manager" style="display: none;">
  <!-- This component manages audio state globally -->
  <!-- UI components can import and use the exposed methods and stores -->
</div>

<style>
  .audio-manager {
    /* Hidden service component */
    position: fixed;
    top: -9999px;
    left: -9999px;
  }
</style>