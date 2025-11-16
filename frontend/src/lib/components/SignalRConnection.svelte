// SignalR Connection Manager - Phoenix LiveView inspired real-time messaging
<script lang="ts">
  import { onMount, onDestroy } from 'svelte';
  import { writable } from 'svelte/store';
  import { HubConnectionBuilder, LogLevel, HubConnection } from '@microsoft/signalr';

  // Enterprise connection state management
  interface ConnectionState {
    status: 'disconnected' | 'connecting' | 'connected' | 'reconnecting' | 'failed';
    connectionId: string | null;
    lastActivity: Date | null;
    retryCount: number;
    messages: Array<{
      id: string;
      timestamp: Date;
      type: string;
      payload: any;
    }>;
  }

  // Reactive store for connection state
  export const connectionState = writable<ConnectionState>({
    status: 'disconnected',
    connectionId: null,
    lastActivity: null,
    retryCount: 0,
    messages: []
  });

  // Configuration with enterprise defaults
  export let hubUrl: string = '/api/hub';
  export let autoReconnect: boolean = true;
  export let enableLogging: boolean = true;
  export let sessionId: string = crypto.randomUUID();

  let connection: HubConnection | null = null;
  let reconnectTimer: number | null = null;
  let heartbeatTimer: number | null = null;

  // BEAM-inspired supervision and fault tolerance
  onMount(async () => {
    await initializeConnection();
  });

  onDestroy(() => {
    cleanup();
  });

  // Initialize SignalR connection with enterprise features
  async function initializeConnection() {
    try {
      connectionState.update(state => ({ 
        ...state, 
        status: 'connecting',
        retryCount: 0
      }));

      // Build connection with advanced configuration
      const connectionBuilder = new HubConnectionBuilder()
        .withUrl(hubUrl, {
          withCredentials: true,
          headers: {
            'X-Session-Id': sessionId
          }
        })
        .withAutomaticReconnect({
          nextRetryDelayInMilliseconds: (retryContext) => {
            // Exponential backoff with jitter (enterprise pattern)
            const baseDelay = Math.min(1000 * Math.pow(2, retryContext.previousRetryCount), 30000);
            const jitter = Math.random() * 1000;
            return baseDelay + jitter;
          }
        });

      // Add logging in development
      if (enableLogging && process.env.NODE_ENV === 'development') {
        connectionBuilder.configureLogging(LogLevel.Information);
      }

      connection = connectionBuilder.build();

      // Setup event handlers
      setupConnectionEvents();
      setupMessageHandlers();

      // Start connection
      await connection.start();
      
      // Join session group for targeted messaging
      await connection.invoke('JoinGroup', sessionId);

      connectionState.update(state => ({
        ...state,
        status: 'connected',
        connectionId: connection?.connectionId || null,
        lastActivity: new Date()
      }));

      startHeartbeat();

    } catch (error) {
      console.error('SignalR connection failed:', error);
      connectionState.update(state => ({
        ...state,
        status: 'failed'
      }));
      
      if (autoReconnect) {
        scheduleReconnect();
      }
    }
  }

  // Connection event handlers (Phoenix LiveView pattern)
  function setupConnectionEvents() {
    if (!connection) return;

    connection.onclose((error) => {
      console.log('SignalR connection closed:', error);
      connectionState.update(state => ({
        ...state,
        status: 'disconnected',
        connectionId: null
      }));

      stopHeartbeat();

      if (autoReconnect && error) {
        scheduleReconnect();
      }
    });

    connection.onreconnecting((error) => {
      console.log('SignalR reconnecting:', error);
      connectionState.update(state => ({
        ...state,
        status: 'reconnecting',
        retryCount: state.retryCount + 1
      }));
    });

    connection.onreconnected((connectionId) => {
      console.log('SignalR reconnected:', connectionId);
      connectionState.update(state => ({
        ...state,
        status: 'connected',
        connectionId,
        lastActivity: new Date(),
        retryCount: 0
      }));

      // Rejoin groups after reconnection
      connection?.invoke('JoinGroup', sessionId);
      startHeartbeat();
    });
  }

  // Message handlers for cross-service communication
  function setupMessageHandlers() {
    if (!connection) return;

    // Audio processing events
    connection.on('AudioProcessed', (data) => {
      handleMessage('audio-processed', data);
    });

    connection.on('TranscriptionComplete', (data) => {
      handleMessage('transcription-complete', data);
    });

    // Real-time messages (Phoenix LiveView style)
    connection.on('ReceiveMessage', (message) => {
      handleMessage('message', message);
    });

    connection.on('ReceiveAudioData', (audioData) => {
      handleMessage('audio-data', audioData);
    });

    // System events
    connection.on('UserJoined', (user) => {
      handleMessage('user-joined', user);
    });

    connection.on('UserLeft', (user) => {
      handleMessage('user-left', user);
    });

    // Enterprise events
    connection.on('SystemAlert', (alert) => {
      handleMessage('system-alert', alert);
      // Could trigger toast notifications or other UI updates
    });
  }

  // Message handler with enterprise logging
  function handleMessage(type: string, payload: any) {
    const message = {
      id: crypto.randomUUID(),
      timestamp: new Date(),
      type,
      payload
    };

    connectionState.update(state => ({
      ...state,
      messages: [...state.messages.slice(-99), message], // Keep last 100 messages
      lastActivity: new Date()
    }));

    // Emit custom events for components to listen to
    const customEvent = new CustomEvent(`signalr-${type}`, {
      detail: payload
    });
    window.dispatchEvent(customEvent);
  }

  // Heartbeat mechanism (fault tolerance)
  function startHeartbeat() {
    heartbeatTimer = window.setInterval(async () => {
      try {
        await connection?.invoke('Ping');
        connectionState.update(state => ({
          ...state,
          lastActivity: new Date()
        }));
      } catch (error) {
        console.warn('Heartbeat failed:', error);
      }
    }, 30000); // 30-second heartbeat
  }

  function stopHeartbeat() {
    if (heartbeatTimer) {
      clearInterval(heartbeatTimer);
      heartbeatTimer = null;
    }
  }

  // Automatic reconnection with exponential backoff
  function scheduleReconnect() {
    if (reconnectTimer) return;

    connectionState.update(state => {
      const delay = Math.min(5000 * Math.pow(2, state.retryCount), 60000);
      
      reconnectTimer = window.setTimeout(async () => {
        reconnectTimer = null;
        await initializeConnection();
      }, delay);

      return {
        ...state,
        retryCount: state.retryCount + 1
      };
    });
  }

  // Public API methods (C# style interface)
  export async function sendMessage(type: string, payload: any) {
    if (!connection || connection.state !== 'Connected') {
      throw new Error('SignalR connection not available');
    }

    try {
      await connection.invoke('SendMessage', sessionId, {
        type,
        payload,
        timestamp: new Date().toISOString()
      });
    } catch (error) {
      console.error('Failed to send message:', error);
      throw error;
    }
  }

  export async function sendAudioData(audioData: any) {
    if (!connection) return;

    try {
      await connection.invoke('SendAudioData', sessionId, audioData);
    } catch (error) {
      console.error('Failed to send audio data:', error);
    }
  }

  export async function joinGroup(groupName: string) {
    if (!connection) return;

    try {
      await connection.invoke('JoinGroup', groupName);
    } catch (error) {
      console.error('Failed to join group:', error);
    }
  }

  export async function leaveGroup(groupName: string) {
    if (!connection) return;

    try {
      await connection.invoke('LeaveGroup', groupName);
    } catch (error) {
      console.error('Failed to leave group:', error);
    }
  }

  export function getConnection(): HubConnection | null {
    return connection;
  }

  // Cleanup function
  function cleanup() {
    stopHeartbeat();
    
    if (reconnectTimer) {
      clearTimeout(reconnectTimer);
      reconnectTimer = null;
    }

    if (connection) {
      connection.stop();
      connection = null;
    }
  }

  // Export state and connection for external use
  export { connectionState as state };
</script>

<!-- Hidden service component -->
<div class="signalr-manager" style="display: none;">
  <!-- Connection status indicator could be added here if needed -->
</div>

<style>
  .signalr-manager {
    position: fixed;
    top: -9999px;
    left: -9999px;
  }
</style>