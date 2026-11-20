const projectPattern = /^[a-z][a-z0-9-]{4,28}[a-z0-9]$/;

export function readOptions(argv, allowedFlags) {
  const options = {};
  for (let i = 0; i < argv.length; i += 1) {
    const key = argv[i];
    if (!allowedFlags.includes(key) || key in options) {
      throw new Error(`Unknown or repeated option: ${key}`);
    }
    if (['--apply', '--update-existing', '--offline-plan', '--grant', '--revoke'].includes(key)) {
      options[key] = true;
    } else {
      const value = argv[++i];
      if (!value || value.startsWith('--')) {
        throw new Error(`Missing value for ${key}`);
      }
      options[key] = value;
    }
  }
  return options;
}

export function requireEbookDevelopmentProject(projectId) {
  if (!projectId || !projectPattern.test(projectId)) {
    throw new Error('Provide a valid --project-id for the Ebook development project.');
  }
  if (/coffee|prod(?:uction)?/i.test(projectId) ||
      projectId === 'demo-ebook' || !/ebook/i.test(projectId) ||
      !/(?:^|-)dev(?:elopment)?(?:-|$)/i.test(projectId)) {
    throw new Error('Refusing a project that is not clearly Ebook development.');
  }
  return projectId;
}

export function requireApplyConfirmation(options) {
  if (options['--apply'] && options['--confirm-project'] !== options['--project-id']) {
    throw new Error('--apply requires --confirm-project with the exact same project ID.');
  }
}

export function explainError(error) {
  console.error(`Error: ${error.message}`);
  process.exitCode = 1;
}
