<!-- Audio Control Component - Enterprise UI with borrowed Material Design -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { audioState } from './AudioManager.svelte';

  export let compact: boolean = false;
  
  let mounted = false;
  let audioManager: any;

  onMount(async () => {
    mounted = true;
    // Dynamic import of AudioManager for hot-swappable functionality
    const { default: AudioManager } = await import('./AudioManager.svelte');
    audioManager = new AudioManager({
      target: document.body,
      props: { sessionId: crypto.randomUUID() }
    });
  });

  function handleToggleRecording() {
    audioManager?.toggleRecording?.();
  }

  // Reactive statements for enterprise state management
  $: isRecording = $audioState.isRecording;
  $: isProcessing = $audioState.isProcessing;
  $: audioLevel = $audioState.audioLevel;
  $: hasError = $audioState.error !== null;
</script>

<div class="audio-control" class:compact>
  {#if mounted}
    <!-- Recording Button with Material Design -->
    <md-filled-tonal-button
      class="record-button"
      class:recording={isRecording}
      class:processing={isProcessing}
      class:error={hasError}
      disabled={isProcessing}
      on:click={handleToggleRecording}
    >
      <md-icon slot="icon">
        {#if isProcessing}
          hourglass_empty
        {:else if isRecording}
          stop
        {:else if hasError}
          error
        {:else}
          mic
        {/if}
      </md-icon>
      
      {#if !compact}
        {#if isProcessing}
          Processing...
        {:else if isRecording}
          Stop Recording
        {:else if hasError}
          Audio Error
        {:else}
          Start Recording
        {/if}
      {/if}
    </md-filled-tonal-button>

    <!-- Audio Level Indicator (Phoenix LiveView inspired real-time updates) -->
    {#if isRecording && !compact}
      <div class="audio-level-container ml-3">
        <div class="audio-level-bar">
          <div 
            class="audio-level-fill"
            style="width: {audioLevel * 100}%"
          ></div>
        </div>
        <span class="audio-level-text text-xs text-slate-400">
          {Math.round(audioLevel * 100)}%
        </span>
      </div>
    {/if}

    <!-- Compact Audio Level Indicator -->
    {#if isRecording && compact}
      <div class="audio-level-dot ml-2">
        <div 
          class="dot"
          style="opacity: {0.3 + (audioLevel * 0.7)}"
        ></div>
      </div>
    {/if}
  {:else}
    <!-- Fallback for SSR/loading state -->
    <button 
      class="fallback-button px-4 py-2 bg-slate-700 text-slate-300 rounded-lg
             hover:bg-slate-600 transition-colors"
      disabled
    >
      <span class="mr-2">🎤</span>
      {compact ? '' : 'Loading Audio...'}
    </button>
  {/if}
</div>

<style>
  .audio-control {
    display: flex;
    align-items: center;
  }

  .audio-control.compact {
    font-size: 0.875rem;
  }

  /* Material Design button customization */
  :global(.record-button) {
    --md-filled-tonal-button-container-color: rgb(51, 65, 85);
    --md-filled-tonal-button-label-text-color: rgb(226, 232, 240);
    --md-filled-tonal-button-icon-color: rgb(226, 232, 240);
    transition: all 0.3s ease;
  }

  :global(.record-button.recording) {
    --md-filled-tonal-button-container-color: rgb(239, 68, 68);
    --md-filled-tonal-button-label-text-color: white;
    --md-filled-tonal-button-icon-color: white;
    animation: recording-pulse 1.5s ease-in-out infinite;
  }

  :global(.record-button.processing) {
    --md-filled-tonal-button-container-color: rgb(59, 130, 246);
    --md-filled-tonal-button-label-text-color: white;
    --md-filled-tonal-button-icon-color: white;
  }

  :global(.record-button.error) {
    --md-filled-tonal-button-container-color: rgb(220, 38, 38);
    --md-filled-tonal-button-label-text-color: white;
    --md-filled-tonal-button-icon-color: white;
  }

  @keyframes recording-pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
  }

  /* Audio level visualization */
  .audio-level-container {
    display: flex;
    align-items: center;
    gap: 8px;
  }

  .audio-level-bar {
    width: 60px;
    height: 4px;
    background: rgba(148, 163, 184, 0.2);
    border-radius: 2px;
    overflow: hidden;
  }

  .audio-level-fill {
    height: 100%;
    background: linear-gradient(90deg, #10b981, #f59e0b, #ef4444);
    border-radius: 2px;
    transition: width 0.1s ease;
    animation: audio-glow 1s ease-in-out infinite alternate;
  }

  @keyframes audio-glow {
    0% { box-shadow: 0 0 5px rgba(16, 185, 129, 0.5); }
    100% { box-shadow: 0 0 10px rgba(16, 185, 129, 0.8); }
  }

  /* Compact audio level indicator */
  .audio-level-dot {
    display: flex;
    align-items: center;
  }

  .dot {
    width: 8px;
    height: 8px;
    background: linear-gradient(45deg, #10b981, #f59e0b);
    border-radius: 50%;
    animation: dot-pulse 0.5s ease-in-out infinite alternate;
  }

  @keyframes dot-pulse {
    0% { transform: scale(0.8); }
    100% { transform: scale(1.2); }
  }

  /* Fallback button styling */
  .fallback-button {
    opacity: 0.7;
    cursor: not-allowed;
  }

  /* Enterprise responsive design */
  @media (max-width: 640px) {
    .audio-control:not(.compact) {
      font-size: 0.875rem;
    }
    
    .audio-level-bar {
      width: 40px;
    }
  }
</style>