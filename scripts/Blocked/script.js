const params = new URLSearchParams(location.search);
const target = params.get("target");

document.getElementById("submit").onclick = () => {
	const reason = document.getElementById("reason").value.trim();

	if (reason.length < 50) {
		alert("You must enter at least 50 characters.");
		return;
	}
	const hostname = new URL(target).hostname;

	chrome.storage.local.get(["log", "bypass"], (data) => {
		const log = data.log || [];
		const bypass = data.bypass || {};

		log.push({
			time: Date.now(),
			url: target,
			reason
		});

		// allow for 3 minutes
		bypass[hostname] = Date.now() + 3 * 60 * 1000;

		chrome.storage.local.set({ log, bypass }, () => {
			const delayMs = 30 * 1000;
			const start = Date.now();

			const status = document.createElement("p");
			document.body.appendChild(status);

			const interval = setInterval(() => {
				const elapsed = Date.now() - start;
				const remaining = Math.max(0, delayMs - elapsed);

				status.textContent = `Wait ${Math.ceil(remaining / 1000)} seconds...`;

				if (remaining <= 0) {
					clearInterval(interval);
					window.location.href = target;
				}
			}, 200);
		});
	});
};
