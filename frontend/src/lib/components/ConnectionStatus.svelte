<!-- Connection Status Component - BEAM supervision inspired -->
<script lang="ts">
  import { onMount } from 'svelte';
  import { connectionState } from './SignalRConnection.svelte';

  export let compact: boolean = false;

  let mounted = false;

  onMount(() => {
    mounted = true;
  });

  // Reactive state mapping
  $: status = $connectionState.status;
  $: retryCount = $connectionState.retryCount;
  $: lastActivity = $connectionState.lastActivity;

  // Status configuration (enterprise patterns)
  const statusConfig = {
    connected: {
      icon: 'wifi',
      color: 'text-green-400',
      bgColor: 'bg-green-400/20',
      label: 'Connected',
      description: 'Real-time connection active'
    },
    connecting: {
      icon: 'wifi_find',
      color: 'text-yellow-400',
      bgColor: 'bg-yellow-400/20',
      label: 'Connecting',
      description: 'Establishing connection...'
    },
    reconnecting: {
      icon: 'sync',
      color: 'text-blue-400',
      bgColor: 'bg-blue-400/20',
      label: 'Reconnecting',
      description: `Retry ${retryCount}/5`
    },
    disconnected: {
      icon: 'wifi_off',
      color: 'text-slate-400',
      bgColor: 'bg-slate-400/20',
      label: 'Disconnected',
      description: 'No real-time connection'
    },
    failed: {
      icon: 'error',
      color: 'text-red-400',
      bgColor: 'bg-red-400/20',
      label: 'Failed',
      description: 'Connection error'
    }
  };

  $: config = statusConfig[status] || statusConfig.disconnected;
</script>

<div class="connection-status" class:compact>
  {#if compact}
    <!-- Compact Status Indicator -->
    <div 
      class="status-dot flex items-center gap-2"
      title="{config.label} - {config.description}"
    >
      {#if mounted}
        <md-icon 
          class="status-icon {config.color} text-sm"
          class:animate-spin={status === 'connecting' || status === 'reconnecting'}
        >
          {config.icon}
        </md-icon>
      {:else}
        <div class="fallback-dot w-2 h-2 rounded-full {config.bgColor}"></div>
      {/if}
      
      <span class="status-text text-xs {config.color}">
        {config.label}
      </span>
    </div>
  {:else}
    <!-- Full Status Display -->
    <div class="status-card glass-effect rounded-lg p-3 border border-slate-700/50">
      <div class="flex items-center gap-3">
        <!-- Status Icon with Animation -->
        <div class="status-icon-container {config.bgColor} rounded-full p-2">
          {#if mounted}
            <md-icon 
              class="status-icon {config.color}"
              class:animate-spin={status === 'connecting' || status === 'reconnecting'}
              class:animate-pulse={status === 'connected'}
            >
              {config.icon}
            </md-icon>
          {:else}
            <div class="fallback-icon w-4 h-4 rounded-full {config.bgColor}"></div>
          {/if}
        </div>

        <!-- Status Information -->
        <div class="status-info flex-1">
          <div class="flex items-center gap-2">
            <span class="status-label font-medium text-sm {config.color}">
              {config.label}
            </span>
            
            {#if status === 'connected' && lastActivity}
              <span class="last-activity text-xs text-slate-500">
                Active {formatLastActivity(lastActivity)}
              </span>
            {/if}
          </div>
          
          <p class="status-description text-xs text-slate-400 mt-1">
            {config.description}
          </p>
        </div>

        <!-- Connection Strength Indicator (Phoenix LiveView inspired) -->
        {#if status === 'connected'}
          <div class="signal-bars flex gap-1">
            {#each Array(4) as _, i}
              <div 
                class="bar bg-green-400 opacity-{i < 3 ? '100' : '30'}"
                style="height: {(i + 1) * 3 + 2}px"
              ></div>
            {/each}
          </div>
        {/if}
      </div>

      <!-- Enterprise Metrics (when expanded) -->
      {#if status === 'connected' && $connectionState.connectionId}
        <div class="metrics mt-3 pt-3 border-t border-slate-700/30">
          <div class="grid grid-cols-2 gap-4 text-xs">
            <div>
              <span class="text-slate-500">Connection ID</span>
              <p class="text-slate-300 font-mono truncate">
                {$connectionState.connectionId.substring(0, 8)}...
              </p>
            </div>
            <div>
              <span class="text-slate-500">Messages</span>
              <p class="text-slate-300">
                {$connectionState.messages.length}
              </p>
            </div>
          </div>
        </div>
      {/if}
    </div>
  {/if}
</div>

<script>
  // Utility function for time formatting
  function formatLastActivity(date) {
    const now = new Date();
    const diff = now.getTime() - date.getTime();
    const seconds = Math.floor(diff / 1000);
    
    if (seconds < 60) return `${seconds}s ago`;
    if (seconds < 3600) return `${Math.floor(seconds / 60)}m ago`;
    return `${Math.floor(seconds / 3600)}h ago`;
  }
</script>

<style>
  .connection-status {
    font-family: 'Rajdhani', sans-serif;
  }

  .glass-effect {
    background: rgba(15, 23, 42, 0.6);
    backdrop-filter: blur(8px);
    -webkit-backdrop-filter: blur(8px);
  }

  .status-card {
    min-width: 250px;
    transition: all 0.3s ease;
  }

  .status-card:hover {
    background: rgba(15, 23, 42, 0.8);
    border-color: rgba(148, 163, 184, 0.3);
  }

  /* Status icon animations */
  .status-icon-container {
    transition: all 0.3s ease;
  }

  .animate-pulse {
    animation: gentle-pulse 2s ease-in-out infinite;
  }

  @keyframes gentle-pulse {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.7; }
  }

  /* Signal bars animation */
  .signal-bars .bar {
    width: 2px;
    background: linear-gradient(to top, #10b981, #34d399);
    border-radius: 1px;
    animation: signal-wave 1.5s ease-in-out infinite;
  }

  .signal-bars .bar:nth-child(1) { animation-delay: 0s; }
  .signal-bars .bar:nth-child(2) { animation-delay: 0.1s; }
  .signal-bars .bar:nth-child(3) { animation-delay: 0.2s; }
  .signal-bars .bar:nth-child(4) { animation-delay: 0.3s; }

  @keyframes signal-wave {
    0%, 100% { opacity: 0.3; }
    50% { opacity: 1; }
  }

  /* Compact mode styling */
  .connection-status.compact .status-dot {
    min-width: 80px;
  }

  /* Enterprise error states */
  .connection-status :global(.status-icon.text-red-400) {
    animation: error-flash 1s ease-in-out infinite;
  }

  @keyframes error-flash {
    0%, 100% { opacity: 1; }
    50% { opacity: 0.5; }
  }

  /* Responsive design */
  @media (max-width: 640px) {
    .status-card {
      min-width: 200px;
      padding: 0.75rem;
    }
    
    .metrics {
      grid-template-columns: 1fr;
      gap: 8px;
    }
  }
</style>