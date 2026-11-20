'use strict'

const root = document.documentElement
const themeButton = document.getElementById('theme-button')
const themeColour = document.querySelector('meta[name="theme-color"]')

function showTheme(theme) {
  root.dataset.theme = theme
  const label = theme === 'dark' ? 'Use light theme' : 'Use dark theme'
  themeButton.setAttribute('aria-label', label)
  themeButton.title = label
  themeColour.content = theme === 'dark' ? '#0b0b0d' : '#f5f5f3'
}
showTheme(root.dataset.theme)
themeButton.addEventListener('click', () => {
  const next = root.dataset.theme === 'dark' ? 'light' : 'dark'
  showTheme(next)
  try { localStorage.setItem('stillforce-page-theme', next) } catch {}
})

const menuButton = document.getElementById('menu-button')
const nav = document.getElementById('navigation')
const compactHeader = matchMedia('(max-width: 47.99rem)')

function setMenu(open) {
  menuButton.setAttribute('aria-expanded', String(open))
  menuButton.setAttribute('aria-label', open ? 'Close navigation' : 'Open navigation')
  nav.dataset.open = String(open)
}
menuButton.addEventListener('click', () => setMenu(menuButton.getAttribute('aria-expanded') !== 'true'))
nav.addEventListener('click', event => {
  const link = event.target.closest('a')
  if (!link || nav.dataset.open !== 'true') return
  setMenu(false)
  const heading = document.querySelector(link.hash)?.querySelector('h2')
  if (heading) {
    heading.tabIndex = -1
    heading.focus({ preventScroll: true })
  }
})
document.addEventListener('keydown', event => {
  if (event.key === 'Escape' && nav.dataset.open === 'true') {
    setMenu(false)
    menuButton.focus()
  }
})
document.addEventListener('pointerdown', event => {
  if (nav.dataset.open === 'true' && !event.target.closest('.masthead')) setMenu(false)
})
compactHeader.addEventListener('change', () => setMenu(false))

const artWindow = document.getElementById('art-window')
const artName = document.getElementById('art-name')
const artChoices = [...document.querySelectorAll('.art-choice')]
const portraits = [artWindow.querySelector('.portrait')]
let activeArt = 0
let requestedArt = 0

function getPortrait(index) {
  if (!portraits[index]) {
    const image = new Image()
    image.className = 'portrait'
    image.alt = ''
    image.decoding = 'async'
    image.src = artChoices[index].dataset.image
    artWindow.append(image)
    portraits[index] = image
  }
  return portraits[index]
}

async function selectArt(index) {
  requestedArt = index
  if (index === activeArt) {
    artName.textContent = artChoices[index].dataset.name
    return
  }
  const image = getPortrait(index)
  try {
    await image.decode()
  } catch {
    // Keep the displayed artwork intact and allow another attempt.
    if (portraits[index] !== image) return
    image.remove()
    portraits[index] = null
    if (requestedArt === index) artName.textContent = artChoices[activeArt].dataset.name + ' · Artwork could not load'
    return
  }
  if (requestedArt !== index || activeArt === index) return
  portraits[activeArt].classList.remove('is-current')
  artChoices[activeArt].setAttribute('aria-pressed', 'false')
  activeArt = index
  image.classList.add('is-current')
  const choice = artChoices[index]
  choice.setAttribute('aria-pressed', 'true')
  artWindow.setAttribute('aria-label', choice.dataset.description)
  artName.textContent = choice.dataset.name
}

artChoices.forEach((choice, index) => {
  choice.addEventListener('pointerenter', () => getPortrait(index))
  choice.addEventListener('focus', () => getPortrait(index))
  choice.addEventListener('click', () => selectArt(index))
  choice.addEventListener('keydown', event => {
    let target
    switch (event.key) {
      case 'ArrowDown':
      case 'ArrowRight': target = (index + 1) % artChoices.length; break
      case 'ArrowUp':
      case 'ArrowLeft': target = (index + artChoices.length - 1) % artChoices.length; break
      case 'Home': target = 0; break
      case 'End': target = artChoices.length - 1; break
      default: return
    }
    event.preventDefault()
    artChoices[target].focus()
    selectArt(target)
  })
})

let touchStart
artWindow.addEventListener('pointerdown', event => {
  if (!event.isPrimary || event.pointerType === 'mouse') return
  touchStart = { x: event.clientX, y: event.clientY, id: event.pointerId }
})
artWindow.addEventListener('pointercancel', () => { touchStart = null })
artWindow.addEventListener('pointerup', event => {
  if (!touchStart || event.pointerId !== touchStart.id) return
  const dx = event.clientX - touchStart.x
  const dy = event.clientY - touchStart.y
  touchStart = null
  if (Math.abs(dx) < 42 || Math.abs(dx) < Math.abs(dy) * 1.3) return
  const direction = dx < 0 ? 1 : -1
  selectArt((requestedArt + direction + artChoices.length) % artChoices.length)
})

const galleryTabs = document.querySelector('.gallery-tabs')
const tabs = [...galleryTabs.querySelectorAll('[data-panel]')]
const panels = tabs.map(tab => document.getElementById('view-' + tab.dataset.panel))
galleryTabs.setAttribute('role', 'tablist')

function showPanel(selected, moveFocus) {
  tabs.forEach((tab, i) => {
    const active = i === selected
    tab.setAttribute('aria-selected', String(active))
    tab.tabIndex = active ? 0 : -1
    tab.classList.toggle('selected', active)
    panels[i].hidden = !active
  })
  if (moveFocus) tabs[selected].focus()
}
tabs.forEach((tab, i) => {
  const panel = panels[i]
  tab.id = 'tab-' + tab.dataset.panel
  tab.setAttribute('role', 'tab')
  tab.setAttribute('aria-controls', panel.id)
  panel.setAttribute('role', 'tabpanel')
  panel.setAttribute('aria-labelledby', tab.id)
  tab.addEventListener('click', event => {
    if (event.ctrlKey || event.metaKey || event.shiftKey || event.altKey) return
    event.preventDefault()
    showPanel(i, false)
  })
  tab.addEventListener('keydown', event => {
    let target = i
    switch (event.key) {
      case 'ArrowRight': target = (i + 1) % tabs.length; break
      case 'ArrowLeft': target = (i + tabs.length - 1) % tabs.length; break
      case 'Home': target = 0; break
      case 'End': target = tabs.length - 1; break
      case ' ': break
      default: return
    }
    event.preventDefault()
    showPanel(target, true)
  })
})
showPanel(0, false)

const film = document.getElementById('trailer-player')
const startFilm = document.getElementById('film-start')
const soundButton = document.getElementById('film-sound')
let filmHasPlayed = false
let mutedForAutoplay = false
let playbackRequest = 0

function updateSoundButton() {
  if (!film.muted) mutedForAutoplay = false
  soundButton.hidden = !mutedForAutoplay || film.volume === 0 || film.paused || film.ended
}

function restoreTrailerSound() {
  // Preserve a visitor's mute choice. Only undo the browser-policy fallback.
  if (!mutedForAutoplay) return
  mutedForAutoplay = false
  film.muted = false
  soundButton.hidden = true
}

function showFilmControls() {
  film.controls = true
  startFilm.hidden = true
}

async function playFilm() {
  playbackRequest++
  restoreTrailerSound()
  showFilmControls()
  film.focus({ preventScroll: true })
  try {
    await film.play()
  } catch {
    // The native controls and the download link also work when playback is blocked.
  }
}
film.controls = false
startFilm.addEventListener('click', playFilm)
soundButton.addEventListener('click', playFilm)
document.getElementById('hero-trailer').addEventListener('click', event => {
  if (!event.ctrlKey && !event.metaKey && !event.shiftKey && !event.altKey) playFilm()
})
film.addEventListener('play', () => {
  if (!film.paused) playbackRequest++
  filmHasPlayed = true
  showFilmControls()
  updateSoundButton()
})
film.addEventListener('volumechange', updateSoundButton)
film.addEventListener('pause', updateSoundButton)
film.addEventListener('ended', () => {
  film.controls = false
  startFilm.hidden = false
  startFilm.setAttribute('aria-label', 'Replay the Stillforce trailer')
  updateSoundButton()
})

if ('IntersectionObserver' in window) {
  const reducedMotion = matchMedia('(prefers-reduced-motion: reduce)')
  const enterRatio = 0.5
  const exitRatio = 0.25
  let inView = false
  let intersects = false
  let resumeOnReturn = true

  async function playOnEntry() {
    if (!resumeOnReturn || reducedMotion.matches || !film.paused) return
    const request = ++playbackRequest
    restoreTrailerSound()
    try {
      await film.play()
      return
    } catch (error) {
      if (error.name !== 'NotAllowedError') return
    }

    // Visibility or a visitor's playback choice may have changed during the request.
    if (request !== playbackRequest || !inView || document.hidden || reducedMotion.matches) return
    if (film.muted || !film.paused) return
    mutedForAutoplay = true
    film.muted = true
    try {
      await film.play()
    } catch {
      if (request === playbackRequest && film.paused) restoreTrailerSound()
    }
  }

  function pauseOnExit() {
    playbackRequest++
    // Remember a visitor's pause before pausing for the viewport or tab.
    resumeOnReturn = !filmHasPlayed || !film.paused || film.ended
    if (!film.paused) film.pause()
  }

  const observer = new IntersectionObserver(entries => {
    const previous = inView
    let leftScreen = false
    for (const entry of entries) {
      if (intersects && !entry.isIntersecting) leftScreen = true
      intersects = entry.isIntersecting
      if (!intersects || entry.intersectionRatio < exitRatio) inView = false
      else if (entry.intersectionRatio >= enterRatio) inView = true
    }
    if (document.hidden) return
    if (inView && !previous) playOnEntry()
    else if (!inView && (previous || (leftScreen && !intersects && !film.paused))) pauseOnExit()
  }, { threshold: [0, exitRatio, enterRatio] })
  observer.observe(film)
  film.addEventListener('play', () => {
    if (intersects && !film.paused) inView = true
  })
  document.addEventListener('visibilitychange', () => {
    if (document.hidden) {
      if (inView || !film.paused) pauseOnExit()
    } else if (inView) playOnEntry()
  })
}

root.classList.add('js')
