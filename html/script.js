const resourceName = typeof GetParentResourceName === 'function' ? GetParentResourceName() : 'dach-multijob';

const app = document.getElementById('app');
const jobList = document.getElementById('job-list');
const emptyEl = document.getElementById('empty');
const titleEl = document.getElementById('title');
const subtitleEl = document.getElementById('subtitle');
const hintEl = document.getElementById('hint');
const btnClose = document.getElementById('btn-close');
const btnDuty = document.getElementById('btn-duty');

let audioCtx = null;

function updateDutyButton(onDuty, dutyToggle, locale) {
    if (!btnDuty) return;
    if (!dutyToggle) {
        btnDuty.classList.add('hidden');
        return;
    }
    btnDuty.classList.remove('hidden');
    const loc = locale || {};
    if (onDuty) {
        btnDuty.textContent = loc.duty_go_off || 'Go off duty';
        btnDuty.classList.remove('btn-duty--off');
        btnDuty.title = loc.duty_go_off || '';
    } else {
        btnDuty.textContent = loc.duty_go_on || 'Go on duty';
        btnDuty.classList.add('btn-duty--off');
        btnDuty.title = loc.duty_go_on || '';
    }
}

function getAudio() {
    if (!audioCtx) {
        try {
            const AC = window.AudioContext || window.webkitAudioContext;
            if (!AC) return null;
            audioCtx = new AC();
        } catch (e) {
            return null;
        }
    }
    if (audioCtx.state === 'suspended') {
        audioCtx.resume().catch(() => {});
    }
    return audioCtx;
}

function playTone(freq, duration, type, vol) {
    const ctx = getAudio();
    if (!ctx) return;
    const osc = ctx.createOscillator();
    const gain = ctx.createGain();
    osc.type = type || 'sine';
    osc.frequency.value = freq;
    gain.gain.value = vol || 0.08;
    osc.connect(gain);
    gain.connect(ctx.destination);
    const now = ctx.currentTime;
    gain.gain.setValueAtTime(vol || 0.08, now);
    gain.gain.exponentialRampToValueAtTime(0.001, now + duration);
    osc.start(now);
    osc.stop(now + duration);
}

function soundHover() {
    playTone(880, 0.04, 'sine', 0.06);
}

function soundClick() {
    const ctx = getAudio();
    if (!ctx) return;
    playTone(523, 0.06, 'triangle', 0.1);
    setTimeout(() => playTone(784, 0.08, 'sine', 0.06), 40);
}

function soundOpen() {
    playTone(440, 0.12, 'sine', 0.05);
    setTimeout(() => playTone(554, 0.1, 'sine', 0.045), 80);
}

function soundClose() {
    playTone(330, 0.1, 'sine', 0.05);
}

function postNui(name, data) {
    fetch(`https://${resourceName}/${name}`, {
        method: 'POST',
        headers: { 'Content-Type': 'application/json; charset=UTF-8' },
        body: JSON.stringify(data || {}),
    }).catch(() => {});
}

function closeUi() {
    soundClose();
    app.classList.add('hidden');
    postNui('close');
}

function renderJobs(jobs, locale) {
    jobList.innerHTML = '';
    if (!jobs || jobs.length === 0) {
        emptyEl.textContent = locale.empty || 'No jobs.';
        emptyEl.classList.remove('hidden');
        return;
    }
    emptyEl.classList.add('hidden');

    jobs.forEach((job) => {
        const li = document.createElement('li');
        li.className = 'job-item' + (job.active ? ' active' : '');
        li.dataset.name = job.name;

        const info = document.createElement('div');
        info.className = 'job-info';
        const name = document.createElement('div');
        name.className = 'job-name';
        name.textContent = job.label || job.name;
        const meta = document.createElement('div');
        meta.className = 'job-meta';
        meta.textContent = job.gradeLabel ? `${job.gradeLabel} · L${job.grade}` : `L${job.grade}`;
        info.appendChild(name);
        info.appendChild(meta);

        const right = document.createElement('div');
        right.className = 'badge';
        if (job.active) {
            const b = document.createElement('span');
            b.className = 'badge-active';
            b.textContent = locale.current || 'Active';
            right.appendChild(b);
        }

        li.appendChild(info);
        li.appendChild(right);

        li.addEventListener('mouseenter', () => {
            soundHover();
        });
        li.addEventListener('click', () => {
            if (job.active) {
                li.classList.add('pulse');
                return;
            }
            soundClick();
            li.classList.add('pulse');
            postNui('selectJob', { name: job.name });
        });

        jobList.appendChild(li);
    });
}

function applyOpenPayload(data, playSound) {
    const loc = data.locale || {};
    const panel = document.querySelector('.panel');
    if (panel) {
        if (data.disableBackdropBlur) {
            panel.classList.add('no-blur');
        } else {
            panel.classList.remove('no-blur');
        }
    }
    titleEl.textContent = loc.title || 'MULTI JOB';
    subtitleEl.textContent = loc.subtitle || '';
    hintEl.textContent = loc.close_hint || 'ESC to close';
    renderJobs(data.jobs, loc);
    updateDutyButton(data.onDuty === true, data.dutyToggle === true, loc);
    app.classList.remove('hidden');
    if (playSound) soundOpen();
}

window.addEventListener('message', (event) => {
    const data = event.data;
    if (!data || !data.action) return;

    if (data.action === 'open') {
        applyOpenPayload(data, true);
    }

    if (data.action === 'refresh') {
        applyOpenPayload(data, false);
    }

    if (data.action === 'close') {
        app.classList.add('hidden');
    }
});

btnClose.addEventListener('click', closeUi);

if (btnDuty) {
    btnDuty.addEventListener('click', (e) => {
        e.preventDefault();
        soundClick();
        postNui('toggleDuty');
    });
}

document.addEventListener('keydown', (e) => {
    if (e.key === 'Escape') {
        if (!app.classList.contains('hidden')) {
            closeUi();
        }
    }
});
