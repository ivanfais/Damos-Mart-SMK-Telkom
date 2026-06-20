import React, { useState } from 'react';
import { Store } from 'lucide-react';

interface LogoProps {
  className?: string;
  iconClassName?: string;
}

/**
 * Damos Mart brand logo.
 * Loads /logo-damos.png from the public folder (transparent background).
 */
export const Logo: React.FC<LogoProps> = ({ className = 'w-10 h-10', iconClassName = 'w-6 h-6' }) => {
  const [failed, setFailed] = useState(false);

  if (failed) {
    return (
      <div className={`flex items-center justify-center text-brand-600 ${className}`}>
        <Store className={iconClassName} />
      </div>
    );
  }

  return (
    <img
      src="/logo-damos.png"
      alt="Logo Damos Mart"
      className={`object-contain ${className}`}
      onError={() => setFailed(true)}
    />
  );
};

export default Logo;
