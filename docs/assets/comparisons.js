(() => {
  const updateImageComparison = (comparison, input) => {
    const value = Number(input.value);
    const firstLabel = input.dataset.firstLabel || "first image";
    const secondLabel = input.dataset.secondLabel || "second image";
    comparison.style.setProperty("--compare-position", `${value}%`);
    input.setAttribute("aria-valuetext", `${value}% ${firstLabel}, ${100 - value}% ${secondLabel}`);
  };

  document.querySelectorAll("[data-image-compare]").forEach((comparison) => {
    const input = comparison.querySelector("[data-image-compare-input]");
    if (!input) return;
    updateImageComparison(comparison, input);
    input.addEventListener("input", () => updateImageComparison(comparison, input));
  });

  document.querySelectorAll("[data-video-compare]").forEach((comparison) => {
    const videos = [...comparison.querySelectorAll("video")];
    const playButton = comparison.querySelector("[data-video-play]");
    const pauseButton = comparison.querySelector("[data-video-pause]");
    const restartButton = comparison.querySelector("[data-video-restart]");
    const status = comparison.querySelector("[data-video-status]");
    if (videos.length !== 2 || !playButton || !pauseButton || !restartButton || !status) return;

    const setStatus = (message) => { status.textContent = message; };
    const rewindIfFinished = (video) => {
      if (video.ended || (Number.isFinite(video.duration) && video.currentTime >= video.duration - 0.05)) {
        video.currentTime = 0;
      }
    };

    playButton.addEventListener("click", () => {
      videos.forEach(rewindIfFinished);
      const starts = videos.map((video) => video.play());
      Promise.allSettled(starts).then((results) => {
        const rejected = results.filter((result) => result.status === "rejected").length;
        setStatus(rejected ? "Playback was blocked; use each video control." : "Playing both · timelines remain independent");
      });
    });

    pauseButton.addEventListener("click", () => {
      videos.forEach((video) => video.pause());
      setStatus("Both paused");
    });

    restartButton.addEventListener("click", () => {
      videos.forEach((video) => {
        video.pause();
        if (video.readyState > 0) {
          video.currentTime = 0;
        } else {
          video.addEventListener("loadedmetadata", () => { video.currentTime = 0; }, { once: true });
        }
      });
      setStatus("Both returned to the start");
    });

    videos.forEach((video) => {
      video.addEventListener("ended", () => {
        const complete = videos.filter((item) => item.ended).length;
        setStatus(complete === 2 ? "Both finished" : "One finished · the other is still playing");
      });
    });
  });
})();
