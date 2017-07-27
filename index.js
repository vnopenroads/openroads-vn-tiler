const exec = require('child_process').exec;

function runShellScript (script, callback) {
  const runscript = exec(script, null, callback);
  runscript.stdout.pipe(process.stdout);
  runscript.stderr.pipe(process.stderr);
  runscript.on('close', (code) => {
    console.error(`Exited ${script} with code ${code}`);
  });
}

const whichScript = process.env.WHICH_SCRIPT || 'make-network';
runShellScript(`./scripts/${whichScript}.sh`);
