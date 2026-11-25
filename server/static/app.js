// Lockin - Modern Viewport Frontend Controller
document.addEventListener('DOMContentLoaded', () => {
  const urlParams = new URLSearchParams(window.location.search);
  const targetUrl = urlParams.get('url') || '';
  const browser = urlParams.get('browser') || 'Browser';
  const reason = urlParams.get('reason') || 'Likely entertainment';

  // --------------------------------------------------------------------------
  // Resolve Target Domain & Display Title (Dynamic, never hardcoded static text)
  // --------------------------------------------------------------------------
  let domain = '';
  if (targetUrl) {
    try {
      const parsedUrl = new URL(targetUrl);
      domain = parsedUrl.hostname.replace(/^www\./, '');
    } catch (e) { }
  }

  const rawTitle = urlParams.get('title');
  let title = rawTitle ? rawTitle.trim() : '';

  if (!title) {
    if (domain) {
      if (domain.toLowerCase().includes('youtube') || domain.toLowerCase().includes('youtu.be')) {
        title = 'YouTube Distraction';
      } else if (domain.toLowerCase().includes('instagram')) {
        title = 'Instagram Feed';
      } else if (domain.toLowerCase().includes('sonyliv')) {
        title = 'Sony LIV Streaming';
      } else if (domain.toLowerCase().includes('netflix')) {
        title = 'Netflix Streaming';
      } else {
        title = domain.charAt(0).toUpperCase() + domain.slice(1);
      }
    } else {
      title = 'Distraction Intercepted';
    }
  }

  if (!domain) {
    domain = 'Blocked Target';
  }

  // --------------------------------------------------------------------------
  // 1. Theme Management (Light & Dark Mode)
  // --------------------------------------------------------------------------
  const themeToggleBtn = document.getElementById('themeToggleBtn');
  const metaColorScheme = document.querySelector('meta[name="color-scheme"]');

  function getRenderedScheme() {
    if (metaColorScheme && (metaColorScheme.content === 'dark' || metaColorScheme.content === 'light')) {
      return metaColorScheme.content;
    }
    return window.matchMedia('(prefers-color-scheme: dark)').matches ? 'dark' : 'light';
  }

  function applyTheme(targetScheme) {
    if (metaColorScheme) {
      metaColorScheme.content = targetScheme;
    }
    try {
      localStorage.setItem('color-scheme', targetScheme);
    } catch (e) { }
    if (themeToggleBtn) {
      themeToggleBtn.setAttribute(
        'title',
        targetScheme === 'dark' ? 'Switch to Light mode (Bulb)' : 'Switch to Dark mode (Half Moon)'
      );
    }
  }

  if (themeToggleBtn) {
    themeToggleBtn.addEventListener('click', () => {
      const current = getRenderedScheme();
      const next = current === 'dark' ? 'light' : 'dark';
      applyTheme(next);
    });
  }

  // Theme URL override (useful for testing and explicit query embedding)
  const themeParam = urlParams.get('theme');
  if (themeParam === 'light' || themeParam === 'dark') {
    applyTheme(themeParam);
  }

  // Cross-tab theme sync
  window.addEventListener('storage', (e) => {
    if (e.key === 'color-scheme' && metaColorScheme && e.newValue) {
      metaColorScheme.content = e.newValue;
    }
  });

  // --------------------------------------------------------------------------
  // 2. Intercepted Target Info Card
  // --------------------------------------------------------------------------
  const blockedTitleEl = document.getElementById('blockedTitle');
  const blockedMetaTextEl = document.getElementById('blockedMetaText');
  const blockedTargetLinkEl = document.getElementById('blockedTargetLink');
  const youtubeBadgeSvg = document.getElementById('youtubeBadgeSvg');
  const genericBadgeSvg = document.getElementById('genericBadgeSvg');

  if (blockedTitleEl) {
    blockedTitleEl.textContent = title;
    blockedTitleEl.title = title;
  }

  if (blockedMetaTextEl) {
    const cleanReason = reason.replace(/\s+Blocked$/, '');
    if (domain.toLowerCase().includes('youtube') || domain.toLowerCase().includes('youtu.be')) {
      blockedMetaTextEl.textContent = `YouTube • ${cleanReason}`;
      if (youtubeBadgeSvg) youtubeBadgeSvg.style.display = 'block';
      if (genericBadgeSvg) genericBadgeSvg.style.display = 'none';
    } else {
      const displayDomain = domain.charAt(0).toUpperCase() + domain.slice(1);
      blockedMetaTextEl.textContent = `${displayDomain} • ${cleanReason}`;
      if (youtubeBadgeSvg) youtubeBadgeSvg.style.display = 'none';
      if (genericBadgeSvg) genericBadgeSvg.style.display = 'block';
    }
  }

  if (blockedTargetLinkEl && targetUrl && !targetUrl.includes('127.0.0.1')) {
    blockedTargetLinkEl.href = targetUrl;
  } else if (blockedTargetLinkEl) {
    blockedTargetLinkEl.style.display = 'none';
  }

  // --------------------------------------------------------------------------
  // 3. Focus Persona Switcher (Islamic Reminder vs Deep Focus)
  // --------------------------------------------------------------------------
  const modeIslamicBtn = document.getElementById('modeIslamicBtn');
  const modeUniversalBtn = document.getElementById('modeUniversalBtn');
  const islamicLeftGroup = document.getElementById('islamicLeftGroup');
  const universalLeftGroup = document.getElementById('universalLeftGroup');
  const footerBrandText = document.getElementById('footerBrandText');
  const targetSessionLabel = document.getElementById('targetSessionLabel');
  const breatheBtn = document.getElementById('breatheBtn');

  // Interactive Tools & Actions Elements
  const closeTabBtn = document.getElementById('closeTabBtn');
  const allowVideoBtn = document.getElementById('allowVideoBtn');
  const tempPassBtn = document.getElementById('tempPassBtn');
  const passBadge = document.getElementById('passBadge');
  const passModal = document.getElementById('passModal');
  const modalDailyRemaining = document.getElementById('modalDailyRemaining');
  const modalDisciplineWins = document.getElementById('modalDisciplineWins');
  const durOption5 = document.getElementById('durOption5');
  const durOption10 = document.getElementById('durOption10');
  const passReasonInput = document.getElementById('passReasonInput');
  const confirmPassBtn = document.getElementById('confirmPassBtn');
  const cancelPassBtn = document.getElementById('cancelPassBtn');
  const activePassBanner = document.getElementById('activePassBanner');
  const activePassTimeRemaining = document.getElementById('activePassTimeRemaining');
  const activePassDomain = document.getElementById('activePassDomain');
  const earlySealBtn = document.getElementById('earlySealBtn');

  // Secular by default: Deep Focus mode is default for all users.
  // Spiritual reflection mode is secondary and opt-in via switcher.
  let currentFocusMode = localStorage.getItem('focuspal_mode') || localStorage.getItem('focus_guardian_mode') || 'universal';
  const modeParam = urlParams.get('mode');
  if (modeParam === 'islamic' || modeParam === 'universal') {
    currentFocusMode = modeParam;
  }

  function applyFocusMode(mode) {
    currentFocusMode = mode;
    try {
      localStorage.setItem('focuspal_mode', mode);
      localStorage.setItem('focus_guardian_mode', mode);
    } catch (e) { }
    document.body.setAttribute('data-focus-mode', mode);

    if (mode === 'universal') {
      if (modeUniversalBtn) {
        modeUniversalBtn.classList.add('active');
        modeUniversalBtn.setAttribute('aria-selected', 'true');
      }
      if (modeIslamicBtn) {
        modeIslamicBtn.classList.remove('active');
        modeIslamicBtn.setAttribute('aria-selected', 'false');
      }
      if (islamicLeftGroup) islamicLeftGroup.style.display = 'none';
      if (universalLeftGroup) universalLeftGroup.style.display = 'flex';
      // In Deep Focus mode: Dhikr is hidden, showing only Pomodoro & Square Breathing!
      if (breatheBtn) breatheBtn.style.display = 'none';
      if (footerBrandText) {
        footerBrandText.textContent = 'Focus Pal • Protecting your attention for Deep Work & Life Mastery';
      }
      if (targetSessionLabel) targetSessionLabel.textContent = 'Deep Focus';
    } else {
      if (modeIslamicBtn) {
        modeIslamicBtn.classList.add('active');
        modeIslamicBtn.setAttribute('aria-selected', 'true');
      }
      if (modeUniversalBtn) {
        modeUniversalBtn.classList.remove('active');
        modeUniversalBtn.setAttribute('aria-selected', 'false');
      }
      if (universalLeftGroup) universalLeftGroup.style.display = 'none';
      if (islamicLeftGroup) islamicLeftGroup.style.display = 'flex';
      // In Islamic Reminder mode: Dhikr is shown!
      if (breatheBtn) breatheBtn.style.display = 'flex';
      if (footerBrandText) {
        footerBrandText.textContent = 'Focus Pal • Protecting your time for your Future & the Akhirah';
      }
      if (targetSessionLabel) targetSessionLabel.textContent = 'Deep Focus';
    }
  }

  if (modeIslamicBtn) {
    modeIslamicBtn.addEventListener('click', () => applyFocusMode('islamic'));
  }
  if (modeUniversalBtn) {
    modeUniversalBtn.addEventListener('click', () => applyFocusMode('universal'));
  }

  applyFocusMode(currentFocusMode);

  // --------------------------------------------------------------------------
  // 4. Action: Return to Work (Close Tab or Go Back)
  // --------------------------------------------------------------------------
  function executeCloseTab() {
    if (closeTabBtn) {
      closeTabBtn.disabled = true;
      closeTabBtn.innerHTML = `
        <svg width="18" height="18" viewBox="0 0 24 24" fill="none" stroke="currentColor" stroke-width="2.5" stroke-linecap="round" stroke-linejoin="round">
          <circle cx="12" cy="12" r="10"></circle>
          <polyline points="12 6 12 12 14 14"></polyline>
        </svg>
        <span>Returning to Work...</span>
      `;
    }

    // 1. If user navigated to this distraction from an earlier work page in the same tab:
    // Go back in history (skipping the distraction URL so it doesn't re-trigger block)
    if (window.history.length > 2) {
      window.history.go(-2);
      return;
    }

    // 2. Otherwise (fresh distraction tab): Close the distraction tab to return focus to desktop/IDE
    fetch(`/api/close-tab?browser=${encodeURIComponent(browser)}`, { method: 'POST' })
      .finally(() => {
        window.close();
        setTimeout(() => {
          window.location.href = 'about:blank';
        }, 300);
      });
  }

  if (closeTabBtn) {
    closeTabBtn.addEventListener('click', executeCloseTab);
  }

  // --------------------------------------------------------------------------
  // 5. Action: Allow Video & Watch (Strictly YouTube Videos)
  // --------------------------------------------------------------------------
  if (allowVideoBtn) {
    const isYouTubeVideo = /(?:v=|\/shorts\/|\/embed\/|youtu\.be\/)([a-zA-Z0-9_-]{11})/.test(targetUrl);

    if (!isYouTubeVideo || targetUrl.includes('127.0.0.1') || targetUrl.includes('localhost')) {
      allowVideoBtn.style.display = 'none';
      if (tempPassBtn) tempPassBtn.classList.add('full-width');
    } else {
      allowVideoBtn.style.display = 'flex';
      if (tempPassBtn) tempPassBtn.classList.remove('full-width');
      allowVideoBtn.addEventListener('click', async (e) => {
        e.preventDefault();
        allowVideoBtn.disabled = true;
        allowVideoBtn.innerHTML = `<span>Allowing & Opening...</span>`;

        try {
          await fetch(`/api/allow-target?title=${encodeURIComponent(title)}&url=${encodeURIComponent(targetUrl)}`, {
            method: 'POST',
            keepalive: true
          });
        } catch (err) {
          console.error("Failed to allow target:", err);
        }

        setTimeout(() => {
          window.location.replace(targetUrl);
        }, 120);
      });
    }
  }

  // --------------------------------------------------------------------------
  // 6. Intentional Dopamine Pass System (Hybrid Model)
  // --------------------------------------------------------------------------
  let selectedPassDuration = 5;
  let passCountdownInterval = null;
  let passTickerInterval = null;

  async function fetchPassStatus() {
    try {
      const res = await fetch('/api/pass-status');
      if (!res.ok) return;
      const status = await res.json();

      if (passBadge) {
        passBadge.textContent = `${status.daily_remaining} left`;
        if (status.daily_remaining <= 0) {
          passBadge.style.background = 'rgba(239, 68, 68, 0.2)';
          passBadge.style.color = '#ef4444';
        } else {
          passBadge.style.background = 'var(--gold-primary)';
          passBadge.style.color = '#1e293b';
        }
      }

      if (modalDailyRemaining) {
        modalDailyRemaining.textContent = `${status.daily_remaining} of ${status.daily_limit}`;
      }
      if (modalDisciplineWins) {
        modalDisciplineWins.textContent = status.early_seals_today;
      }

      // Active Pass Banner
      if (status.active_pass && status.active_pass.status === 'active') {
        if (activePassBanner) activePassBanner.style.display = 'flex';
        if (activePassDomain) activePassDomain.textContent = status.active_pass.target_domain;
        startActivePassTicker(status.active_pass.expires_at);
      } else {
        if (activePassBanner) activePassBanner.style.display = 'none';
        if (passTickerInterval) clearInterval(passTickerInterval);
      }

      return status;
    } catch (e) {
      console.error('Failed to load pass status:', e);
    }
  }

  function startActivePassTicker(expiresAt) {
    if (passTickerInterval) clearInterval(passTickerInterval);
    function updateTicker() {
      const now = Date.now() / 1000;
      const diff = Math.max(0, Math.floor(expiresAt - now));
      const m = Math.floor(diff / 60);
      const s = diff % 60;
      if (activePassTimeRemaining) {
        activePassTimeRemaining.textContent = `${m}:${s < 10 ? '0' : ''}${s}`;
      }
      if (diff <= 0) {
        clearInterval(passTickerInterval);
        fetchPassStatus();
      }
    }
    updateTicker();
    passTickerInterval = setInterval(updateTicker, 1000);
  }

  if (durOption5 && durOption10) {
    durOption5.addEventListener('click', () => {
      selectedPassDuration = 5;
      durOption5.classList.add('active');
      durOption10.classList.remove('active');
      if (confirmPassBtn && !confirmPassBtn.disabled) {
        confirmPassBtn.textContent = 'Confirm & Unlock (5m)';
      }
    });
    durOption10.addEventListener('click', () => {
      selectedPassDuration = 10;
      durOption10.classList.add('active');
      durOption5.classList.remove('active');
      if (confirmPassBtn && !confirmPassBtn.disabled) {
        confirmPassBtn.textContent = 'Confirm & Unlock (10m)';
      }
    });
  }

  if (tempPassBtn && passModal) {
    if (!targetUrl || targetUrl.includes('127.0.0.1') || targetUrl.includes('localhost')) {
      tempPassBtn.style.display = 'none';
    } else {
      tempPassBtn.addEventListener('click', async () => {
        const status = await fetchPassStatus();
        if (!status) return;

        if (status.daily_remaining <= 0) {
          alert('Daily pass quota reached for today. Keep focused on your goals!');
          return;
        }

        if (status.cooldown_remaining_seconds > 0) {
          const mins = Math.ceil(status.cooldown_remaining_seconds / 60);
          alert(`Cooling-off period active. Please wait ${mins} more minute(s) before requesting another pass.`);
          return;
        }

        passModal.showModal();

        // 10s anti-impulse cooling-off delay
        if (passCountdownInterval) clearInterval(passCountdownInterval);
        let secondsLeft = 10;
        confirmPassBtn.disabled = true;
        confirmPassBtn.textContent = `Pause & Reflect (${secondsLeft}s)...`;

        passCountdownInterval = setInterval(() => {
          secondsLeft--;
          if (secondsLeft > 0) {
            confirmPassBtn.textContent = `Pause & Reflect (${secondsLeft}s)...`;
          } else {
            clearInterval(passCountdownInterval);
            passCountdownInterval = null;
            confirmPassBtn.disabled = false;
            confirmPassBtn.textContent = `Confirm & Unlock (${selectedPassDuration}m)`;
          }
        }, 1000);
      });
    }

    passModal.addEventListener('close', () => {
      if (passCountdownInterval) clearInterval(passCountdownInterval);
      passCountdownInterval = null;
      if (confirmPassBtn) {
        confirmPassBtn.disabled = true;
        confirmPassBtn.textContent = 'Pause & Reflect (10s)...';
      }
      if (passReasonInput) passReasonInput.value = '';
    });

    if (cancelPassBtn) {
      cancelPassBtn.addEventListener('click', (e) => {
        e.preventDefault();
        passModal.close('cancel');
      });
    }

    if (confirmPassBtn) {
      confirmPassBtn.addEventListener('click', async (e) => {
        e.preventDefault();
        const reasonVal = (passReasonInput ? passReasonInput.value : '').trim();
        if (reasonVal.length < 3) {
          alert('Please enter a specific reason for this pass (minimum 3 characters).');
          if (passReasonInput) passReasonInput.focus();
          return;
        }

        confirmPassBtn.disabled = true;
        confirmPassBtn.textContent = 'Unlocking...';

        try {
          const res = await fetch(`/api/request-pass?url=${encodeURIComponent(targetUrl)}&duration=${selectedPassDuration}&reason=${encodeURIComponent(reasonVal)}`, {
            method: 'POST',
            keepalive: true
          });
          const json = await res.json();
          if (json.success) {
            passModal.close();
            setTimeout(() => {
              window.location.replace(targetUrl);
            }, 100);
          } else {
            alert('Could not unlock pass: ' + (json.error || 'Unknown error'));
            confirmPassBtn.disabled = false;
            confirmPassBtn.textContent = `Confirm & Unlock (${selectedPassDuration}m)`;
          }
        } catch (err) {
          console.error('Request pass error:', err);
          alert('Network error connecting to local guardian server.');
        }
      });
    }

    if (earlySealBtn) {
      earlySealBtn.addEventListener('click', async () => {
        earlySealBtn.disabled = true;
        earlySealBtn.textContent = 'Sealing...';
        try {
          const res = await fetch('/api/seal-pass', { method: 'POST' });
          const json = await res.json();
          alert(json.message);
          fetchPassStatus();
        } catch (e) {
          console.error('Early seal error:', e);
        } finally {
          earlySealBtn.disabled = false;
          earlySealBtn.textContent = "🔒 Re-Lock Now";
        }
      });
    }
  }

  fetchPassStatus();

  // --------------------------------------------------------------------------
  // 7. Focus Tool 1: 100-Second Dhikr Engine
  // --------------------------------------------------------------------------
  const breatheModal = document.getElementById('breatheModal');
  const stopBreatheBtn = document.getElementById('stopBreatheBtn');
  const extendTimerBtn = document.getElementById('extendTimerBtn');
  const trackDuasBtn = document.getElementById('trackDuasBtn');
  const trackTasbeehBtn = document.getElementById('trackTasbeehBtn');
  const countdownNumber = document.getElementById('countdownNumber');
  const ringProgress = document.getElementById('ringProgress');
  const breatheProgress = document.getElementById('breatheProgress');
  const breathePhase = document.getElementById('breathePhase');
  const breatheInstruction = document.getElementById('breatheInstruction');
  const breatheTranslit = document.getElementById('breatheTranslit');
  const breatheMeaning = document.getElementById('breatheMeaning');
  const breathePrompt = document.getElementById('breathePrompt');

  const RING_CIRCUMFERENCE = 364.4; // 2 * pi * 58
  let dhikrTotalSeconds = 100;
  let dhikrSecondsLeft = 100;
  let dhikrTimerInterval = null;
  let currentTrack = 'tasbeeh';

  const TRACK_TASBEEH = [
    { ar: 'سُبْحَانَ اللَّهِ', translit: 'SubhanAllah', meaning: 'Glory be to Allah', prompt: 'Declare Allah free of all imperfection and detach from transient distraction.' },
    { ar: 'الْحَمْدُ لِلَّهِ', translit: 'Alhamdulillah', meaning: 'All praise is for Allah', prompt: 'Be grateful for the faculties of mind, sight, and time you have been blessed with.' },
    { ar: 'اللَّهُ أَكْبَرُ', translit: 'Allahu Akbar', meaning: 'Allah is the Greatest', prompt: 'Allah and your eternal purpose are far greater than any trivial entertainment.' },
    { ar: 'أَسْتَغْفِرُ اللَّهَ', translit: 'Astaghfirullah', meaning: 'I seek forgiveness from Allah', prompt: 'Cleanse the heart of wasted moments and renew your intention with sincerity.' },
    { ar: 'لَا إِلَٰهَ إِلَّا اللَّهُ', translit: 'La ilaha illa Allah', meaning: 'There is none worthy of worship but Allah', prompt: 'Center your heart solely on your Creator and return with honor to beneficial work.' }
  ];

  const TRACK_DUAS = [
    { ar: 'سُبْحَانَ اللَّهِ وَبِحَمْدِهِ ، سُبْحَانَ اللَّهِ الْعَظِيمِ', translit: 'SubhanAllahi wa bihamdihi, SubhanAllahil Azeem', meaning: 'Glory be to Allah and His is the praise, Glory be to Allah the Supreme', prompt: 'Two phrases light on the tongue, heavy on the scales, and beloved to the Most Merciful.' },
    { ar: 'حَسْبُنَا اللَّهُ وَنِعْمَ الْوَكِيلُ', translit: 'HasbunAllahu wa ni\'mal wakeel', meaning: 'Allah is sufficient for us, and He is the best disposer of affairs', prompt: 'Entrust all your stresses, fears, and exams to Allah; He will suffice your every need.' },
    { ar: 'رَبِّ اشْرَحْ لِي صَدْرِي وَيَسِّرْ لِي أَمْرِي', translit: 'Rabbi-shrah li sadri wa yassir li amri', meaning: 'My Lord, expand for me my chest and make easy for me my task', prompt: 'The prophetic prayer of Prophet Musa (AS) asking Allah for clarity, speech, and focus in hard study.' }
  ];

  function updateDhikrStage(remaining, total) {
    const elapsed = total - remaining;

    if (currentTrack === 'duas') {
      let stageIdx = 0;
      let stageName = '';
      if (elapsed < 33) {
        stageIdx = 0;
        stageName = '1 of 3 • Praise';
      } else if (elapsed < 66) {
        stageIdx = 1;
        stageName = '2 of 3 • Trust';
      } else {
        stageIdx = 2;
        stageName = '3 of 3 • Ease';
      }
      const item = TRACK_DUAS[stageIdx];
      if (breathePhase) breathePhase.textContent = `Prophetic Dua ${stageName}`;
      if (breatheInstruction) breatheInstruction.textContent = item.ar;
      if (breatheTranslit) breatheTranslit.textContent = item.translit;
      if (breatheMeaning) breatheMeaning.textContent = item.meaning;
      if (breathePrompt) breathePrompt.textContent = item.prompt;
    } else {
      const stageDuration = Math.max(1, Math.floor(total / 5));
      const stageIdx = Math.min(4, Math.floor(elapsed / stageDuration));
      const item = TRACK_TASBEEH[stageIdx];
      if (breathePhase) breathePhase.textContent = `Remembrance ${stageIdx + 1} of 5 • ${stageDuration}s`;
      if (breatheInstruction) breatheInstruction.textContent = item.ar;
      if (breatheTranslit) breatheTranslit.textContent = item.translit;
      if (breatheMeaning) breatheMeaning.textContent = item.meaning;
      if (breathePrompt) breathePrompt.textContent = item.prompt;
    }
  }

  function stopDhikrTimer() {
    if (dhikrTimerInterval) {
      clearInterval(dhikrTimerInterval);
      dhikrTimerInterval = null;
    }
  }

  function startOrResumeDhikrTimer() {
    stopDhikrTimer();
    updateDhikrStage(dhikrSecondsLeft, dhikrTotalSeconds);

    dhikrTimerInterval = setInterval(() => {
      dhikrSecondsLeft--;
      if (countdownNumber) countdownNumber.textContent = dhikrSecondsLeft;

      if (ringProgress) {
        const offset = RING_CIRCUMFERENCE * (1 - dhikrSecondsLeft / dhikrTotalSeconds);
        ringProgress.style.strokeDashoffset = offset.toFixed(1);
      }

      if (breatheProgress) {
        breatheProgress.value = dhikrTotalSeconds - dhikrSecondsLeft;
        breatheProgress.max = dhikrTotalSeconds;
        breatheProgress.setAttribute('aria-valuenow', String(dhikrTotalSeconds - dhikrSecondsLeft));
      }

      updateDhikrStage(dhikrSecondsLeft, dhikrTotalSeconds);

      if (dhikrSecondsLeft <= 0) {
        stopDhikrTimer();
        if (breathePhase) breathePhase.textContent = 'Completed • MashaAllah';
        if (breatheInstruction) breatheInstruction.textContent = 'مَا شَاءَ اللَّهُ تَبَارَكَ اللَّهُ';
        if (breatheTranslit) breatheTranslit.textContent = 'MashaAllah TabarakAllah';
        if (breatheMeaning) breatheMeaning.textContent = `${dhikrTotalSeconds}s Remembrance Completed • Heart cleansed and mind focused.`;
        setTimeout(() => {
          if (dhikrSecondsLeft <= 0 && breatheModal && breatheModal.open) {
            breatheModal.close();
          }
        }, 3200);
      }
    }, 1000);
  }

  function switchTrack(trackKey) {
    if (currentTrack === trackKey) return;
    currentTrack = trackKey;

    if (trackDuasBtn && trackTasbeehBtn) {
      if (trackKey === 'duas') {
        trackDuasBtn.classList.add('active');
        trackDuasBtn.setAttribute('aria-selected', 'true');
        trackTasbeehBtn.classList.remove('active');
        trackTasbeehBtn.setAttribute('aria-selected', 'false');
      } else {
        trackTasbeehBtn.classList.add('active');
        trackTasbeehBtn.setAttribute('aria-selected', 'true');
        trackDuasBtn.classList.remove('active');
        trackDuasBtn.setAttribute('aria-selected', 'false');
      }
    }
    updateDhikrStage(dhikrSecondsLeft, dhikrTotalSeconds);
  }

  if (trackDuasBtn) trackDuasBtn.addEventListener('click', () => switchTrack('duas'));
  if (trackTasbeehBtn) trackTasbeehBtn.addEventListener('click', () => switchTrack('tasbeeh'));

  if (extendTimerBtn) {
    extendTimerBtn.addEventListener('click', () => {
      const EXTENSION = 60;
      dhikrSecondsLeft += EXTENSION;
      dhikrTotalSeconds += EXTENSION;
      if (countdownNumber) countdownNumber.textContent = dhikrSecondsLeft;
      if (breatheProgress) breatheProgress.max = dhikrTotalSeconds;
      startOrResumeDhikrTimer();
    });
  }

  if (breatheBtn && breatheModal) {
    breatheBtn.addEventListener('click', () => {
      dhikrTotalSeconds = 100;
      dhikrSecondsLeft = 100;
      switchTrack('tasbeeh');
      if (countdownNumber) countdownNumber.textContent = dhikrSecondsLeft;
      if (ringProgress) ringProgress.style.strokeDashoffset = '0';
      if (breatheProgress) {
        breatheProgress.value = 0;
        breatheProgress.max = dhikrTotalSeconds;
        breatheProgress.setAttribute('aria-valuenow', '0');
      }
      breatheModal.showModal();
      startOrResumeDhikrTimer();
    });

    breatheModal.addEventListener('close', () => {
      stopDhikrTimer();
      breatheModal.returnValue = '';
    });

    if (stopBreatheBtn) {
      stopBreatheBtn.addEventListener('click', () => breatheModal.close());
    }
  }

  // --------------------------------------------------------------------------
  // 8. Focus Tool 2: Square / Box Breathing Engine (4-4-4-4)
  // --------------------------------------------------------------------------
  const boxBreatheBtn = document.getElementById('boxBreatheBtn');
  const boxBreathingModal = document.getElementById('boxBreathingModal');
  const stopBoxBtn = document.getElementById('stopBoxBtn');
  const extendBoxBtn = document.getElementById('extendBoxBtn');
  const boxFrame = document.getElementById('boxFrame');
  const boxCountdownNumber = document.getElementById('boxCountdownNumber');
  const boxPhaseBadge = document.getElementById('boxPhaseBadge');
  const boxBreatheInstruction = document.getElementById('boxBreatheInstruction');
  const boxBreatheSub = document.getElementById('boxBreatheSub');

  let boxInterval = null;
  let boxCycleCurrent = 1;
  let boxCycleTotal = 4;
  let boxPhaseIdx = 0;
  let boxSecondsInPhase = 4;

  const BOX_PHASES = [
    { name: 'Inhale', class: 'phase-inhale', title: 'Inhale Deeply', sub: 'Breathe in smoothly through your nose, expanding your diaphragm (4s).' },
    { name: 'Hold', class: 'phase-hold-in', title: 'Hold with Stillness', sub: 'Rest gently at the top of your breath without strain (4s).' },
    { name: 'Exhale', class: 'phase-exhale', title: 'Slow Exhale', sub: 'Release the breath smoothly and slowly through your mouth (4s).' },
    { name: 'Hold', class: 'phase-hold-out', title: 'Hold in Calm', sub: 'Rest in quiet stillness, resetting impulsive dopamine craving (4s).' }
  ];

  function stopBoxBreathing() {
    if (boxInterval) {
      clearInterval(boxInterval);
      boxInterval = null;
    }
    if (boxFrame) {
      boxFrame.classList.remove('running');
    }
  }

  function renderBoxState() {
    const current = BOX_PHASES[boxPhaseIdx];
    if (boxCountdownNumber) boxCountdownNumber.textContent = boxSecondsInPhase;
    if (boxPhaseBadge) boxPhaseBadge.textContent = `Cycle ${boxCycleCurrent} of ${boxCycleTotal} • ${current.name}`;
    if (boxBreatheInstruction) boxBreatheInstruction.textContent = current.title;
    if (boxBreatheSub) boxBreatheSub.textContent = current.sub;

    if (boxFrame) {
      boxFrame.className = 'box-visual-frame running ' + current.class;
    }
  }

  function startBoxBreathing() {
    stopBoxBreathing();
    renderBoxState();

    if (boxFrame) {
      boxFrame.classList.remove('running');
      void boxFrame.offsetWidth; // Trigger reflow to restart CSS animation from (0,0) top-left
      boxFrame.classList.add('running');
    }

    boxInterval = setInterval(() => {
      boxSecondsInPhase--;

      if (boxSecondsInPhase <= 0) {
        boxSecondsInPhase = 4;
        boxPhaseIdx++;

        if (boxPhaseIdx >= 4) {
          boxPhaseIdx = 0;
          boxCycleCurrent++;

          if (boxCycleCurrent > boxCycleTotal) {
            stopBoxBreathing();
            if (boxPhaseBadge) boxPhaseBadge.textContent = 'Completed • Nervous System Reset';
            if (boxBreatheInstruction) boxBreatheInstruction.textContent = 'Peace & Clarity Restored';
            if (boxBreatheSub) boxBreatheSub.textContent = 'Your heart rate is lowered and dopamine craving cleared. Return to your goals.';
            if (boxCountdownNumber) boxCountdownNumber.textContent = '✓';
            setTimeout(() => {
              if (boxBreathingModal && boxBreathingModal.open) {
                boxBreathingModal.close();
              }
            }, 3000);
            return;
          }
        }
      }

      renderBoxState();
    }, 1000);
  }

  if (boxBreatheBtn && boxBreathingModal) {
    boxBreatheBtn.addEventListener('click', () => {
      boxCycleCurrent = 1;
      boxCycleTotal = 4;
      boxPhaseIdx = 0;
      boxSecondsInPhase = 4;
      boxBreathingModal.showModal();
      startBoxBreathing();
    });

    boxBreathingModal.addEventListener('close', () => {
      stopBoxBreathing();
      boxBreathingModal.returnValue = '';
    });

    if (extendBoxBtn) {
      extendBoxBtn.addEventListener('click', () => {
        boxCycleTotal += 1;
        renderBoxState();
      });
    }

    if (stopBoxBtn) {
      stopBoxBtn.addEventListener('click', () => boxBreathingModal.close());
    }
  }

  // --------------------------------------------------------------------------
  // 9. Focus Tool 3: Pomodoro Focus Sprint Engine (25m Deep Work)
  // --------------------------------------------------------------------------
  const pomodoroBtn = document.getElementById('pomodoroBtn');
  const pomodoroModal = document.getElementById('pomodoroModal');
  const pomodoroToggleBtn = document.getElementById('pomodoroToggleBtn');
  const pomodoroResetBtn = document.getElementById('pomodoroResetBtn');
  const pomodoroExtendBtn = document.getElementById('pomodoroExtendBtn');
  const stopPomodoroBtn = document.getElementById('stopPomodoroBtn');
  const pomodoroTimerDisplay = document.getElementById('pomodoroTimerDisplay');
  const pomodoroRingProgress = document.getElementById('pomodoroRingProgress');
  const pomodoroPhaseBadge = document.getElementById('pomodoroPhaseBadge');
  const pomodoroTaskInput = document.getElementById('pomodoroTaskInput');

  let pomodoroTotalSeconds = 1500;
  let pomodoroSecondsLeft = 1500;
  let pomodoroInterval = null;
  let isPomodoroRunning = false;

  function formatTime(secs) {
    const m = Math.floor(secs / 60);
    const s = secs % 60;
    return `${String(m).padStart(2, '0')}:${String(s).padStart(2, '0')}`;
  }

  function playPomodoroChime() {
    try {
      const AudioCtx = window.AudioContext || window.webkitAudioContext;
      if (!AudioCtx) return;
      const ctx = new AudioCtx();
      const osc = ctx.createOscillator();
      const gain = ctx.createGain();

      osc.type = 'sine';
      osc.frequency.setValueAtTime(587.33, ctx.currentTime);
      osc.frequency.exponentialRampToValueAtTime(880.0, ctx.currentTime + 0.35);

      gain.gain.setValueAtTime(0.3, ctx.currentTime);
      gain.gain.exponentialRampToValueAtTime(0.001, ctx.currentTime + 2.0);

      osc.connect(gain);
      gain.connect(ctx.destination);

      osc.start();
      osc.stop(ctx.currentTime + 2.0);
    } catch (e) { }
  }

  function updatePomodoroUI() {
    if (pomodoroTimerDisplay) {
      pomodoroTimerDisplay.textContent = formatTime(pomodoroSecondsLeft);
    }
    if (pomodoroRingProgress) {
      const offset = RING_CIRCUMFERENCE * (1 - pomodoroSecondsLeft / pomodoroTotalSeconds);
      pomodoroRingProgress.style.strokeDashoffset = offset.toFixed(1);
    }
  }

  function togglePomodoroTimer() {
    if (isPomodoroRunning) {
      clearInterval(pomodoroInterval);
      pomodoroInterval = null;
      isPomodoroRunning = false;
      if (pomodoroToggleBtn) pomodoroToggleBtn.textContent = 'Resume Focus';
      if (pomodoroPhaseBadge) pomodoroPhaseBadge.textContent = 'Sprint Paused';
    } else {
      isPomodoroRunning = true;
      if (pomodoroToggleBtn) pomodoroToggleBtn.textContent = 'Pause Focus';
      const task = (pomodoroTaskInput && pomodoroTaskInput.value.trim()) ? pomodoroTaskInput.value.trim() : 'Deep Work Session';
      if (pomodoroPhaseBadge) pomodoroPhaseBadge.textContent = `Focusing: ${task}`;

      pomodoroInterval = setInterval(() => {
        pomodoroSecondsLeft--;
        updatePomodoroUI();

        if (pomodoroSecondsLeft <= 0) {
          clearInterval(pomodoroInterval);
          pomodoroInterval = null;
          isPomodoroRunning = false;
          playPomodoroChime();
          if (pomodoroPhaseBadge) pomodoroPhaseBadge.textContent = '🎉 Sprint Completed! Well done!';
          if (pomodoroToggleBtn) pomodoroToggleBtn.textContent = 'Start Next Sprint';
        }
      }, 1000);
    }
  }

  function resetPomodoroTimer() {
    if (pomodoroInterval) clearInterval(pomodoroInterval);
    pomodoroInterval = null;
    isPomodoroRunning = false;
    pomodoroTotalSeconds = 1500;
    pomodoroSecondsLeft = 1500;
    updatePomodoroUI();
    if (pomodoroToggleBtn) pomodoroToggleBtn.textContent = 'Start Focus';
    if (pomodoroPhaseBadge) pomodoroPhaseBadge.textContent = 'Focus Session • 25 Minutes';
  }

  if (pomodoroBtn && pomodoroModal) {
    pomodoroBtn.addEventListener('click', () => {
      pomodoroModal.showModal();
      updatePomodoroUI();
    });

    pomodoroModal.addEventListener('close', () => {
      if (pomodoroInterval) clearInterval(pomodoroInterval);
      pomodoroInterval = null;
      isPomodoroRunning = false;
      pomodoroModal.returnValue = '';
    });

    if (pomodoroToggleBtn) pomodoroToggleBtn.addEventListener('click', togglePomodoroTimer);
    if (pomodoroResetBtn) pomodoroResetBtn.addEventListener('click', resetPomodoroTimer);

    if (pomodoroExtendBtn) {
      pomodoroExtendBtn.addEventListener('click', () => {
        pomodoroSecondsLeft += 300;
        pomodoroTotalSeconds += 300;
        updatePomodoroUI();
      });
    }

    if (stopPomodoroBtn) {
      stopPomodoroBtn.addEventListener('click', () => pomodoroModal.close());
    }
  }

  // --------------------------------------------------------------------------
  // 10. Light-Dismiss for Dialogs & Keyboard Shortcuts
  // --------------------------------------------------------------------------
  const allModals = [breatheModal, boxBreathingModal, pomodoroModal, passModal];

  allModals.forEach(modal => {
    if (!modal) return;
    if (!('closedBy' in HTMLDialogElement.prototype)) {
      modal.addEventListener('click', (event) => {
        if (event.target !== modal) return;
        const rect = modal.getBoundingClientRect();
        const isDialogContent = (
          rect.top <= event.clientY &&
          event.clientY <= rect.top + rect.height &&
          rect.left <= event.clientX &&
          event.clientX <= rect.left + rect.width
        );
        if (!isDialogContent) {
          modal.close();
        }
      });
    }
  });

  document.addEventListener('keydown', (e) => {
    const anyModalOpen = allModals.some(m => m && m.open);
    if (anyModalOpen) return;

    if (e.key === 'Escape' || e.key === 'Enter') {
      e.preventDefault();
      executeCloseTab();
    }
  });
});
