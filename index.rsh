'reach 0.1';

export const main = Reach.App(() => {
  const A = Participant('A', {
    // Specify A interact interface here 
  });
  
  const B = Participant('B', {
    // Specify B interact interface here 
  });
  
  init();

  A.publish()
  commit()

  B.publish()
  commit()

  exit()
  
});
