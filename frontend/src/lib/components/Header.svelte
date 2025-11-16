<!-- Enterprise Header with Material Design and Phoenix LiveView patterns -->
<script lang="ts">
  import { page } from '$app/stores';
  import { onMount } from 'svelte';
  import AudioControl from './AudioControl.svelte';
  import ConnectionStatus from './ConnectionStatus.svelte';

  // Enterprise navigation items
  const navItems = [
    { label: 'Home', href: '/', icon: 'home' },
    { label: 'Projects', href: '/projects', icon: 'work' },
    { label: 'About', href: '/about', icon: 'person' },
    { label: 'AI Lab', href: '/ai-lab', icon: 'psychology' },
    { label: 'Contact', href: '/contact', icon: 'contact_mail' }
  ];

  let mobileMenuOpen = false;
  let mounted = false;

  onMount(() => {
    mounted = true;
    // Initialize Material Design components
    import('@material/web/all.js');
  });

  function toggleMobileMenu() {
    mobileMenuOpen = !mobileMenuOpen;
  }

  function closeMobileMenu() {
    mobileMenuOpen = false;
  }
</script>

<header class="enterprise-header glass-effect sticky top-0 z-50 backdrop-blur-lg">
  <nav class="container mx-auto px-6 py-4">
    <div class="flex items-center justify-between">
      <!-- Brand Logo with Orbitron font -->
      <div class="brand-container">
        <a href="/" class="orbitron text-2xl font-bold text-slate-100 hover:text-blue-400 transition-colors">
          <span class="text-gradient">CODEX</span>
          <span class="text-slate-400">SANCTIUM</span>
        </a>
        <div class="brand-subtitle text-xs text-slate-500 orbitron">
          Enterprise AI Portfolio
        </div>
      </div>

      <!-- Desktop Navigation with Material Design -->
      <div class="hidden md:flex items-center space-x-8">
        {#each navItems as item}
          <a 
            href={item.href}
            class="nav-link orbitron font-medium text-slate-300 hover:text-blue-400 
                   transition-all duration-300 relative group"
            class:active={$page.url.pathname === item.href}
          >
            {#if mounted}
              <md-icon class="inline-block mr-2 text-lg">{item.icon}</md-icon>
            {/if}
            {item.label}
            
            <!-- Active indicator -->
            <div class="absolute -bottom-1 left-0 w-0 h-0.5 bg-gradient-to-r 
                        from-blue-400 to-purple-400 group-hover:w-full transition-all duration-300
                        {$page.url.pathname === item.href ? 'w-full' : ''}">
            </div>
          </a>
        {/each}
      </div>

      <!-- Enterprise Controls -->
      <div class="hidden md:flex items-center space-x-4">
        <!-- Real-time Connection Status -->
        <ConnectionStatus />
        
        <!-- Audio Control with enterprise features -->
        <AudioControl />
        
        <!-- Theme Toggle with Material Design -->
        {#if mounted}
          <md-icon-button 
            class="text-slate-300 hover:text-blue-400 transition-colors"
            title="Toggle Theme"
          >
            <md-icon>dark_mode</md-icon>
          </md-icon-button>
        {/if}
      </div>

      <!-- Mobile Menu Button -->
      <button 
        class="md:hidden text-slate-300 hover:text-blue-400 transition-colors"
        on:click={toggleMobileMenu}
        aria-label="Toggle mobile menu"
      >
        {#if mounted}
          <md-icon class="text-2xl">{mobileMenuOpen ? 'close' : 'menu'}</md-icon>
        {:else}
          <span class="text-2xl">{mobileMenuOpen ? '✕' : '☰'}</span>
        {/if}
      </button>
    </div>

    <!-- Mobile Navigation Slide-out (Phoenix LiveView inspired animation) -->
    <div 
      class="mobile-nav md:hidden overflow-hidden transition-all duration-500 ease-in-out"
      class:max-h-0={!mobileMenuOpen}
      class:max-h-96={mobileMenuOpen}
    >
      <div class="py-4 space-y-2">
        {#each navItems as item}
          <a 
            href={item.href}
            class="mobile-nav-link block px-4 py-3 text-slate-300 hover:text-blue-400 
                   hover:bg-slate-800/50 rounded-lg transition-all duration-200
                   orbitron font-medium"
            class:active={$page.url.pathname === item.href}
            on:click={closeMobileMenu}
          >
            {#if mounted}
              <md-icon class="inline-block mr-3 text-lg">{item.icon}</md-icon>
            {/if}
            {item.label}
          </a>
        {/each}
        
        <!-- Mobile Controls -->
        <div class="px-4 py-3 border-t border-slate-700 mt-4 space-y-3">
          <div class="flex items-center justify-between">
            <span class="text-sm text-slate-400">Connection Status</span>
            <ConnectionStatus compact />
          </div>
          
          <div class="flex items-center justify-between">
            <span class="text-sm text-slate-400">Audio Control</span>
            <AudioControl compact />
          </div>
        </div>
      </div>
    </div>
  </nav>

  <!-- Enterprise Progress Bar (Phoenix LiveView inspired) -->
  <div class="progress-container">
    <div class="progress-bar"></div>
  </div>
</header>

<style>
  .enterprise-header {
    background: rgba(15, 23, 42, 0.8);
    border-bottom: 1px solid rgba(148, 163, 184, 0.1);
  }

  .glass-effect {
    backdrop-filter: blur(16px);
    -webkit-backdrop-filter: blur(16px);
  }

  .text-gradient {
    background: linear-gradient(135deg, #3b82f6, #8b5cf6, #06b6d4);
    -webkit-background-clip: text;
    background-clip: text;
    -webkit-text-fill-color: transparent;
    animation: gradient-shift 3s ease-in-out infinite;
  }

  @keyframes gradient-shift {
    0%, 100% { filter: hue-rotate(0deg); }
    50% { filter: hue-rotate(45deg); }
  }

  .nav-link.active {
    color: rgb(96 165 250);
  }

  .mobile-nav-link.active {
    background: rgba(59, 130, 246, 0.1);
    border-left: 3px solid rgb(59, 130, 246);
    color: rgb(96 165 250);
  }

  .progress-container {
    position: absolute;
    bottom: 0;
    left: 0;
    width: 100%;
    height: 2px;
    background: rgba(148, 163, 184, 0.1);
  }

  .progress-bar {
    height: 100%;
    width: 0;
    background: linear-gradient(90deg, #3b82f6, #8b5cf6, #06b6d4);
    transition: width 0.3s ease;
    opacity: 0;
  }

  /* Phoenix LiveView inspired loading state */
  :global(.phx-loading) .progress-bar {
    opacity: 1;
    animation: loading-progress 1s ease-in-out infinite;
  }

  @keyframes loading-progress {
    0% { width: 0%; }
    50% { width: 70%; }
    100% { width: 100%; }
  }

  /* Enterprise responsive design */
  @media (max-width: 768px) {
    .brand-container {
      font-size: 0.9rem;
    }
    
    .brand-subtitle {
      font-size: 0.625rem;
    }
  }

  /* BEAM supervision pattern visual feedback */
  :global(.connection-error) .enterprise-header {
    border-bottom-color: rgba(239, 68, 68, 0.3);
    animation: error-pulse 2s ease-in-out infinite;
  }

  @keyframes error-pulse {
    0%, 100% { border-bottom-color: rgba(239, 68, 68, 0.3); }
    50% { border-bottom-color: rgba(239, 68, 68, 0.6); }
  }
</style>