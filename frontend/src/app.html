<!-- Codex Sanctium Portfolio - Main Layout -->
<script lang="ts">
	import { onMount } from 'svelte';
	import { page } from '$app/stores';
	import Header from '$lib/components/Header.svelte';
	import Footer from '$lib/components/Footer.svelte';
	import AudioManager from '$lib/components/AudioManager.svelte';
	import SignalRConnection from '$lib/components/SignalRConnection.svelte';
	import '../app.css';

	let mounted = false;

	onMount(() => {
		mounted = true;
		
		// Initialize Material Design Components
		import('@material/web/all.js');
		
		// Add enterprise-grade error handling
		window.addEventListener('unhandledrejection', (event) => {
			console.error('Unhandled promise rejection:', event.reason);
		});
	});
</script>

<svelte:head>
	<title>Codex Sanctium - AI Portfolio | Mandlenkosi Vundla</title>
	<meta name="description" content="Enterprise AI Portfolio showcasing cutting-edge development with Svelte, .NET 9, and Phoenix LiveView" />
	<meta name="viewport" content="width=device-width, initial-scale=1.0" />
	<meta name="theme-color" content="#0f172a" />
	
	<!-- Preconnect to external domains for performance -->
	<link rel="preconnect" href="https://fonts.googleapis.com" />
	<link rel="preconnect" href="https://fonts.gstatic.com" crossorigin />
	
	<!-- Enterprise fonts -->
	<link href="https://fonts.googleapis.com/css2?family=Orbitron:wght@400;700;900&family=Rajdhani:wght@300;400;500;600;700&display=swap" rel="stylesheet" />
</svelte:head>

<div class="app min-h-screen bg-slate-950 text-slate-100">
	{#if mounted}
		<!-- Global Audio Manager for microphone and speech features -->
		<AudioManager />
		
		<!-- Real-time SignalR Connection -->
		<SignalRConnection />
	{/if}
	
	<!-- Main Application Structure -->
	<Header />
	
	<main class="flex-1 relative">
		<slot />
	</main>
	
	<Footer />
</div>

<style>
	:global(.app) {
		font-family: 'Rajdhani', sans-serif;
		font-variation-settings: 'wght' 400;
	}
	
	:global(.orbitron) {
		font-family: 'Orbitron', monospace;
	}
	
	/* Enterprise-grade loading states */
	:global(.loading-shimmer) {
		background: linear-gradient(90deg, transparent, rgba(255, 255, 255, 0.1), transparent);
		background-size: 200% 100%;
		animation: shimmer 1.5s infinite;
	}
	
	@keyframes shimmer {
		0% { background-position: -200% 0; }
		100% { background-position: 200% 0; }
	}
	
	/* Fault-tolerant styles for progressive enhancement */
	@supports not (backdrop-filter: blur(10px)) {
		:global(.glass-effect) {
			background-color: rgba(15, 23, 42, 0.9);
		}
	}
</style>